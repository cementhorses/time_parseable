module CementHorses #:nodoc:
  module TimeParseable #:nodoc:
    def self.included(base)
      base.extend ClassMethods
    end

    # +time_parseable+ adds attribute accessors for parsing time for specified
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
    #   <%= f.label :published_at_string, 'Publish at' %>
    #   <%= f.text_field :published_at_string %>
    # 
    # To reduce error, divide it up into its split accessors, +date_string+
    # and +time_string:
    # 
    #   <%= f.label :published_date_string, 'Publish on' %>
    #   <%= f.text_field :published_date_string %>
    #   <%= f.label :published_time_string, 'at' %>
    #   <%= f.text_field :published_time_string %>
    # 
    module ClassMethods
      # Options:
      # * +format+ - a configurable Hash with +time+ and +date+ options, e.g.,
      # 
      #   time_parseable :format => { :time => "%I:%M %p", :date => "%b %d, %Y" }
      # 
      def time_parseable(*args)
        options = args.extract_options!
        format  = HashWithIndifferentAccess.new(options[:format] || {
          :date => "%b %d, %Y", :time => "%I:%M %p"
        })

        if args.empty? && table_exists?
          args = columns.select { |c| c.type == :datetime }.map(&:name) - [:created_at, :updated_at]
        end

        methods = args.inject('') do |string, field|
          string + <<-end_eval
            #{"attr_accessible :#{field}_string" if accessible_attributes}
            
            def #{field}_string
              #{field}.strftime("#{format[:time]} on #{format[:date]}") unless #{field}.nil?
            end

            def #{field}_string=(value)
              self.#{field} = if value.strip.blank?
                nil
              else              
                time = (Time.zone.parse(value) rescue Time.parse(value))
                case time
                when 2.seconds.ago..2.seconds.from_now
                  if value[/now/i]
                    time
                  else
                    errors.add(:#{field}_string, 'is invalid') and nil
                  end
                else
                  time
                end
              end
            end

            def #{field.to_s.sub(/(at|on)$/, 'date')}_string
              #{field}.strftime("#{format[:date]}") unless #{field}.nil?
            end

            def #{field.to_s.sub(/(at|on)$/, 'date')}_string=(value)
              @#{field.to_s.sub(/(at|on)$/, 'date')}_string = value
              unless @#{field.to_s.sub(/(at|on)$/, 'time')}_string.nil?
                self.#{field}_string = @#{field.to_s.sub(/(at|on)$/, 'time')}_string +
                  ' on ' + @#{field.to_s.sub(/(at|on)$/, 'date')}_string
              end
            end

            def #{field.to_s.sub(/(at|on)$/, 'time')}_string
              #{field}.strftime("#{format[:time]}") unless #{field}.nil?
            end

            def #{field.to_s.sub(/(at|on)$/, 'time')}_string=(value)
              @#{field.to_s.sub(/(at|on)$/, 'time')}_string = value
              unless @#{field.to_s.sub(/(at|on)$/, 'date')}_string.nil?
                self.#{field}_string = @#{field.to_s.sub(/(at|on)$/, 'time')}_string +
                  ' on ' + @#{field.to_s.sub(/(at|on)$/, 'date')}_string
              end
            end
          end_eval
        end

        methods += <<-end_eval
          after_validation :timestamp_errors_passed_on

          protected

            def timestamp_errors_passed_on
              #{args.inspect}.each do |field|
                errors.on(field).each do |error|
                  errors.add("\#{field}_string", error)
                  errors.add("\#{field.to_s.sub(/(at|on)$/, 'date')}_string", error)
                end if errors.on(field)
              end
            end
        end_eval

        class_eval methods, __FILE__, __LINE__
      end
    end
  end
end
