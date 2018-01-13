require "db"
require "levenshtein"
require "./schema_enforcer"

class LuckyRecord::Model
  include LuckyRecord::Associations
  include LuckyRecord::SchemaEnforcer

  macro inherited
    FIELDS = [] of {name: Symbol, type: Object, nilable: Bool, autogenerated: Bool}
    ASSOCIATIONS = [] of {name: Symbol, primary_key: Symbol, foreign_key: Symbol, through: Symbol}

    column id : Int32, autogenerated: true
    column created_at : Time, autogenerated: true
    column updated_at : Time, autogenerated: true
  end

  def_equals @id

  def to_param
    id.to_s
  end

  macro table(table_name)
    setup_table_name({{table_name.id}})
    {{yield}}
    setup {{table_name}}
  end

  def delete
    LuckyRecord::Repo.run do |db|
      db.exec "DELETE FROM #{@@table_name} WHERE id = #{id}"
    end
  end

  macro setup(table_name)
    {% table_name = table_name.id %}
    setup_initialize
    setup_db_mapping
    setup_getters
    setup_base_query_class({{table_name}})
    setup_base_form_class({{table_name}})
    setup_fields_method
    add_schema_enforcer_methods_for({{table_name}}, {{ FIELDS }})
  end

  macro setup_table_name(table_name)
    @@table_name = :{{table_name}}
    TABLE_NAME = :{{table_name}}
  end

  macro setup_initialize
    def initialize(
        {% for field in FIELDS %}
          @{{field[:name]}},
        {% end %}
      )
    end
  end

  macro setup_db_mapping
    DB.mapping({
      {% for field in FIELDS %}
        {{field[:name]}}: {
          type: {{field[:type]}}::Lucky::ColumnType,
          nilable: {{field[:nilable]}},
        },
      {% end %}
    })
  end

  macro setup_base_query_class(table_name)
    LuckyRecord::BaseQueryTemplate.setup({{ @type }}, {{ FIELDS }}, {{ ASSOCIATIONS }}, {{ table_name }})
  end

  macro setup_base_form_class(table_name)
    LuckyRecord::BaseFormTemplate.setup({{ @type }}, {{ FIELDS }}, {{ table_name }})
  end

  macro setup_getters
    {% for field in FIELDS %}
      def {{field[:name]}}
        {{ field[:type] }}::Lucky.from_db! @{{field[:name]}}
      end
    {% end %}
  end

  macro column(type_declaration, autogenerated = false)
    {% if type_declaration.type.is_a?(Union) %}
      {% data_type = "#{type_declaration.type.types.first}".id %}
      {% nilable = true %}
    {% else %}
      {% data_type = "#{type_declaration.type}".id %}
      {% nilable = false %}
    {% end %}
    {% FIELDS << {name: type_declaration.var, type: data_type, nilable: nilable.id, autogenerated: autogenerated} %}
  end

  macro setup_fields_method
    def self.column_names : Array(Symbol)
      [
        {% for field in FIELDS %}
          :{{field[:name]}},
        {% end %}
      ]
    end
  end

  macro association(table_name, primary_key = nil, foreign_key = nil, through = nil)
    {% ASSOCIATIONS << {name: table_name.id, primary_key: primary_key, foreign_key: foreign_key, through: through} %}
  end
end
