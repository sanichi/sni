# Sni

A simple Ruby gem for gathering system information across Rails applications. Perfect for sharing system introspection logic between multiple Rails apps.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sni', git: 'https://github.com/mjo/sni.git'
```

For local development:

```ruby
gem 'sni', path: '../sni'
```

And then execute:

```bash
bundle install
```

## Usage

### System Information

```ruby
# Get all system information
system_info = Sni::SysInfo.call

# Returns a hash with:
# {
#   host: "hostname",
#   env: "production" (or "N/A" if not in Rails)
#   ruby: "3.4.5",
#   rails: "7.0.0" (or "N/A" if not in Rails),
#   gem: "3.7.0",
#   bundler: "2.7.0",
#   server: "Passenger 6.0.15" (in production) or "Puma 5.6.4" (in development),
#   postgres: "14.5" (or "N/A" if not using ActiveRecord/PostgreSQL),
#   user: "sanichi",
#   shell: "/bin/bash",
#   pwd: "/var/www/mio/current"
# }

# Use in Rails controllers
class PagesController < ApplicationController
  def env
    @system_info = Sni::SysInfo.call
  end
end

# Use in views
<% @system_info.each do |key, value| %>
  <tr>
    <th><%= key.to_s.humanize %></th>
    <td><%= value %></td>
  </tr>
<% end %>
```

### Bootstrap Layout Helper

Generate responsive Bootstrap grid CSS classes for form controls and layouts:

```ruby
# Simple single row layout
classes = Sni::Layout.call(sm: [2, 3, 3], lg: [1, 2, 3])
# Returns array of CSS class strings:
# [
#   "col-sm-2 offset-sm-2 col-lg-1 offset-lg-3",
#   "col-sm-3 offset-sm-0 col-lg-2 offset-lg-0",
#   "col-sm-3 offset-sm-0 col-lg-3 offset-lg-0"
# ]

# Multiple rows layout
classes = Sni::Layout.call(md: [[3, 3], [2, 4]], lg: [[2, 2], [1, 5]])
# Returns array for each form control across all rows

# Use in Rails views with form helpers
<% layout_classes = Sni::Layout.call(sm: [4, 4, 4], lg: [2, 4, 6]) %>
<% [:name, :email, :message].each_with_index do |field, i| %>
  <div class="<%= layout_classes[i] %>">
    <%= form.text_field field, class: "form-control" %>
  </div>
<% end %>

# Supported breakpoints: xs, sm, md, lg, xl, xxl (xx alias for xxl)
# Column widths: 1-12 (Bootstrap grid system)
# Automatic centering with offset calculation
# Validates input and provides helpful error messages
```

### Bootstrap Centering Helper

Center a single column in the Bootstrap grid with automatic offset calculation:

```ruby
# Center a column at different breakpoints
classes = Sni::Center.call(xs: 10, md: 8, xl: 4)
# Returns: "offset-1 col-10 offset-md-2 col-md-8 offset-xl-4 col-xl-4"

# Single breakpoint centering
classes = Sni::Center.call(sm: 6)
# Returns: "offset-sm-3 col-sm-6"

# Use in Rails views for centered content
<div class="<%= Sni::Center.call(xs: 10, lg: 6) %>">
  <div class="card">
    <!-- Centered card content -->
  </div>
</div>

# Defaults to full width if no breakpoints provided
classes = Sni::Center.call({})
# Returns: "col-12"

# Supported breakpoints: xs, sm, md, lg, xl, xxl (xx alias for xxl)
# Column widths: 1-12 (Bootstrap grid system)
# Automatically calculates offset: (12 - width) / 2
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

**Important:** Always use `bin/rake` (not `rake spec`) when running tests. This ensures Bundler updates Gemfile.lock when the version changes, since the gem is installed as a PATH dependency.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mjo/sni.
