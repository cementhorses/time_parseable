module CementHorses #:nodoc:
  module TimeParseable #:nodoc:
    def self.included(base)
      base.extend ClassMethods
    end

    # +time_parseable+ adds an +attr_accessor+ for parsing time for specified
    # column names or for every timestamp column (less +created_at+ and
    # +updated_at+). Invalid parsing yields errors.
    # 
    # Example:
    # 
    #   # create_table do |t|
    #   #   t.timestamp :published_at, :archived_at
    #   # end
    #   class NewsItem < ActiveRecord::Base
    #     time_parseable
    #   end
    #   
    #   news_item.published_at_string = 'April 30, 2008'
    #   news_item.published_at # => Wed Apr 30 00:00:00 -0000 2008
    #   news_item.archived_at_string = 'Cement Horses'
    #   news_item.archived_at # => nil
    # 
    # Use it in a +form_for+:
    #   
    #   <%= f.label :published_at_string %>
    #   <%= f.text_field :published_at_string %>
    module ClassMethods
      # Options:
      # * +format+ - the <tt>Time#strftime</tt> format for the +_string+
      #   accessor
      def time_parseable(*args)
        options = args.extract_options!
        Time::DATE_FORMATS[:parseable] = options[:format] || "%I:%M %p on %b %d, %Y"

        if args.empty? && table_exists?
          args = columns.select { |c| c.type == :datetime }.map(&:name) - [:created_at, :updated_at]
        end

        methods = args.inject('') do |string, field|
          field_methods = <<-eval
            def #{field}_string
              !#{field}.blank? ? #{field}.to_s(:parseable) : nil
            end

            def #{field}_string=(value)
              self.#{field} = if value.strip.blank?
                nil
              else
                time = Time.parse value
                if time.to_s == Time.now.to_s && !value[/now/i]
                  errors.add(:#{field}_string, 'is invalid') && nil
                else
                  time
                end
              end
            end
          eval

          field_methods += "\nattr_accessible :#{field}_string" if accessible_attributes
          string + field_methods
        end

        methods += <<-eval
          after_validation :pass_along_timestamp_errors

          protected

            def pass_along_timestamp_errors
              #{args.inspect}.each do |field|
                [*errors.on(field)].each do |error|
                  errors.add("\#{field}_string", error)
                end
              end
            end
        eval

        class_eval methods, __FILE__, __LINE__
      end
    end
  end
end
