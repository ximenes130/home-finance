
# Style

We aim to write code that is a pleasure to read, and we have a lot of opinions about how to do it well. Writing great code is an essential part of our programming culture, and we deliberately set a high bar for every code change anyone contributes. We care about how code reads, how code looks, and how code makes you feel when you read it.

We love discussing code. If you have questions about how to write something, or if you detect some smell you are not quite sure how to solve, please ask away to other programmers. A Pull Request is a great way to do this.

When writing new code, unless you are very familiar with our approach, try to find similar code elsewhere to look for inspiration.

## Conditional returns

In general, we prefer to use expanded conditionals over guard clauses.

```ruby
# Bad
def transactions_for_import
  ids = params.require(:csv_import)[:transaction_ids]
  return [] unless ids
  @account.transactions.find(ids.split(","))
end

# Good
def transactions_for_import
  if ids = params.require(:csv_import)[:transaction_ids]
    @account.transactions.find(ids.split(","))
  else
    []
  end
end
```

This is because guard clauses can be hard to read, especially when they are nested.

As an exception, we sometimes use guard clauses to return early from a method:

* When the return is right at the beginning of the method.
* When the main method body is not trivial and involves several lines of code.

```ruby
def after_import_completed(csv_import)
  return if csv_import.failed?

  if csv_import.has_duplicates?
    flag_duplicate_transactions(csv_import)
  else
    finalize_import(csv_import)
  end
end
```

## Methods ordering

We order methods in classes in the following order:

1. `class` methods
2. `public` methods with `initialize` at the top.
3. `private` methods

## Invocation order

We order methods vertically based on their invocation order. This helps us to understand the flow of the code.

```ruby
class SomeClass
  def some_method
    method_1
    method_2
  end

  private
    def method_1
      method_1_1
      method_1_2
    end
  
    def method_1_1
      # ...
    end
  
    def method_1_2
      # ...
    end
  
    def method_2
      method_2_1
      method_2_2
    end
  
    def method_2_1
      # ...
    end
  
    def method_2_2
      # ...
    end
end
```

## To bang or not to bang

Should I call a method `do_something` or `do_something!`?

As a general rule, we only use `!` for methods that have a correspondent counterpart without `!`. In particular, we don’t use `!` to flag destructive actions. There are plenty of destructive methods in Ruby and Rails that do not end with `!`.

## Visibility modifiers

We don't add a newline under visibility modifiers, and we indent the content under them.

```ruby
class SomeClass
  def some_method
    # ...
  end

  private
    def some_private_method_1
      # ...
    end

    def some_private_method_2
      # ...
    end
end
```

If a module only has private methods, we mark it `private` at the top and add an extra new line after but don't indent.

```ruby
module SomeModule
  private
  
  def some_private_method
    # ...
  end
end
```

## CRUD controllers

We model web endpoints as CRUD operations on resources (REST). When an action doesn't map cleanly to a standard CRUD verb, we introduce a new resource rather than adding custom actions.

```ruby
# Bad
resources :accounts do
  post :deactivate
  post :reactivate
end

# Good
resources :accounts do
  resource :activation
end
```

## Controller and model interactions

In general, we favor a [vanilla Rails](https://dev.37signals.com/vanilla-rails-is-plenty/) approach with thin controllers directly invoking a rich domain model. We don't use services or other artifacts to connect the two.

Invoking plain Active Record operations is totally fine:

```ruby
class Accounts::TransactionsController < ApplicationController
  def create
    @transaction = @account.transactions.create!(transaction_params)
  end
end
```

For more complex behavior, we prefer clear, intention-revealing model APIs that controllers call directly:

```ruby
class Accounts::ActivationsController < ApplicationController
  def destroy
    @account.deactivate
  end
end
```

When justified, it is fine to use services or form objects, but don't treat those as special artifacts:

```ruby
CsvImportProcessor.new(csv_import: @csv_import).process
```

## Run async operations in jobs

As a general rule, we write shallow job classes that delegate the logic itself to domain models:

* We typically use the suffix `_later` to flag methods that enqueue a job.
* A common scenario is having a model class that enqueues a job that, when executed, invokes some method in that same class. In this case, we use the suffix `_now` for the regular synchronous method.

```ruby
module CsvImport::Processing
  extend ActiveSupport::Concern

  included do
    after_create_commit :process_later
  end

  def process_later
    CsvImport::ProcessJob.perform_later(self)
  end

  def process_now
    # ...
  end
end

class CsvImport::ProcessJob < ApplicationJob
  def perform(csv_import)
    csv_import.process_now
  end
end
```
