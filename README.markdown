TimeParseable
=============

Time-parse your front-end text-fields.

    $ script/plugin install git://github.com/cementhorses/time_parseable.git


Example
-------

Let's say we want to use text fields for a model...

    # create_table do |t|
    #   t.timestamp :published_at, :archived_at
    # end
    class NewsItem < ActiveRecord::Base
      time_parseable
    end

Now your NewsItem has `published_at_string` and `archived_at_string`, which,
on assignment, are automatically parsed with `Time.parse`.
    
    news_item.published_at_string = 'April 30, 2008'
    news_item.published_at # => Wed Apr 30 00:00:00 -0000 2008

If you only want to parse the `published_at` column, scope it.

    time_parseable :published_at

`Time.parse` is a bit broken, though.

    Time.parse('Cement Horses').to_s == Time.now.to_s # => true

We've fixed it, and added some validation.

    news_item.archived_at_string = 'Cement Horses'
    news_item.archived_at # => nil
    news_item.errors.on(:archived_at) # => 'is invalid'

Now, all you have to do is throw it in a `form_for`, and `time_parseable` will
do the rest.
    
    <%= f.label :published_at_string %>
    <%= f.text_field :published_at_string %>

The field, once populated, will return a `strftime`-formatted result. You can
choose the format (but choose wisely, it should be parse to the same result).

    time_parseable :format => '%I:%M %p on %b %d, %Y'


Copyright (c) 2008 Cement Horses, released under the MIT license
