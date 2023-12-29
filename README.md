# Interactify

[![Gem Version](https://badge.fury.io/rb/interactify.svg)](https://badge.fury.io/rb/interactify)
![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=markburns/interactify)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
![Ruby 3.3.0](https://img.shields.io/badge/ruby-3.3.0-green.svg)
![Ruby 3.2.2](https://img.shields.io/badge/ruby-3.2.2-green.svg)
![Ruby 3.1.4](https://img.shields.io/badge/ruby-3.1.4-green.svg)
![Code Climate](https://codeclimate.com/github/markburns/interactify/badges/gpa.svg)(https://codeclimate.com/github/markburns/interactify)

Interactify enhances Rails applications by simplifying complex interactor chains. 
This gem builds on [interactors](https://github.com/collectiveidea/interactor) and [interactor-contracts](https://github.com/michaelherold/interactor-contracts) to improve readability and maintainability of business logic. 
We depend on activesupport, and optionally on railties and sidekiq. So it's a good fit for Rails projects using Sidekiq, offering advanced features for chain management and debugging. 
Interactify is about making interactor usage in Rails more efficient and less error-prone, reducing the overhead of traditional interactor orchestration.

## Installation

```ruby
gem 'interactify'
```

## Usage

### Initializer

```ruby
# in config/initializers/interactify.rb
Interactify.configure do |config|
  # default
  # config.root = Rails.root / 'app'
end

Interactify.on_contract_breach do |context, attrs|
  # maybe add context to Sentry or Honeybadger etc here
end

Interactify.before_raise do |exception|
  # maybe add context to Sentry or Honeybadger etc here
end
```

### Using the RSpec matchers
```ruby
# e.g. in spec/supoort/interactify.rb
require 'interactify/rspec/matchers'

expect(described_class).to expect_inputs(:foo, :bar, :baz)
expect(described_class).to promise_outputs(:fee, :fi, :fo, :fum)
```

### Syntactic Sugar
- Everything is an Organizer/Interactor and supports interactor-contracts.
- They only becomes considered an organizer once `organize` is called.
- They could technically be both (if you want?) but you have to remember to call `super` within `call` to trigger the organized interactors.
- Concise syntax for most common scenarios with `expects` and `promises`. Verifying the presence of the keys/values.
- Automatic delegation of expected and promised keys to the context.

```ruby
# before

class LoadOrder
  include Interactor
  include Interactor::Contracts

  expects do
    required(:id).filled
    required(:something_else).filled
    required(:a_boolean_flag)
  end

  promises do
    required(:order).filled
  end

  def call
    context.order = Order.find(context.id)
  end
end
```


```ruby
# after
class LoadOrder
  include Interactify

  expect :id, :something_else
  expect :a_boolean_flag, filled: false
  promise :order

  def call
    context.order = Order.find(id)
  end
end
```


### Lambdas

With vanilla interactors, it wasn't possible to use lambdas in organizers.
But sometimes we only want a lambda. So we added support.

```ruby
organize LoadOrder, ->(context) { context.order = context.order.decorate }

organize \
  Thing1, 
  ->(c){ byebug if c.order.nil? },
  Thing2
```

### Each/Iteration

Sometimes we want an interactor for each item in a collection.
But it gets unwieldy. 
It was complex procedural code and is now broken into neat [SRP classes](https://en.wikipedia.org/wiki/Single_responsibility_principle). 
But there is still boilerplate and jumping around between files to follow the orchestration.
It's easy to get lost in the orchestration code that occurs across say 7 or 8 files.

So the complexity problem is just moved to the gaps between the classes and files.
We gain things like `EachOrder`, or `EachProduct` interactors.

Less obvious, still there.

By using `Interactify.each` we can keep the orchestration code in one place.
We get slightly more complex organizers, but a simpler mental model of organizer as orchestrator and SRP interactors.

```ruby
# before
class OuterOrganizer
  # ... boilerplate ...
  organize SetupStep, LoadOrders, DoSomethingWithOrders
end

class LoadOrders
  # ... boilerplate ...
  def call
    context.orders = context.ids.map do |id|
      LoadOrder.call(id: id).order
    end
  end
end

class LoadOrder
  # ... boilerplate ...
  def call
    # ...
  end
end

class DoSomethingWithOrders
  # ... boilerplate ...
  def call
    context.orders.each do |order|
      DoSomethingWithOrder.call(order: order)
    end
  end
end

class DoSomethingWithOrder
  # ... boilerplate ...
  def call
    # ...
  end
end
```

```ruby
# after
class OuterOrganizer
  # ... boilerplate ...
  organize \
    SetupStep,
    self.each(:ids, 
      LoadOrder, 
      ->(c){ byebug if c.order.nil? },
      DoSomethingWithOrder
    )
end

class LoadOrder
  # ... boilerplate ...
  def call
    # ...
  end
end

class DoSomethingWithOrder
  # ... boilerplate ...
  def call
    # ...
  end
end
```

### Conditionals (if/else) with lambda

Along the same lines of each/iteration. We sometimes have to 'break the chain' with interactors just to conditionally call one interactor chain path or another.

The same mental model problem applies. We have to jump around between files to follow the orchestration.

```ruby
# before
class OuterThing
  # ... boilerplate ...
  organize SetupStep, InnerThing
end

class InnerThing
  # ... boilerplate ...
  def call
    if context.thing == 'a'
      DoThingA.call(context)
    else
      DoThingB.call(context)
    end
  end
end
```

```ruby
# after
class OuterThing
  # ... boilerplate ...
  organize \
    SetupStep,
    self.if(->(c){ c.thing == 'a' }, DoThingA, DoThingB),
end

# or hash syntax
class OuterThing
  # ... boilerplate ...
  organize \
    {if: :key_set_on_context, then: DoThingA, else: DoThingB},
    AfterBothCases
end
```

### Conditionals with a key from the context 

```ruby
class OuterThing
  # ... boilerplate ...
  organize \
    self.if(:key_set_on_context, DoThingA, DoThingB),
    AfterBothCases
end
```

### Simple chains
Sometimes you want an organizer that just calls a few interactors in a row.
You may want to create these dynamically at load time, or you may just want to keep the orchestration in one place.

`self.chain` is a simple way to do this.

```ruby
class SomeOrganizer
  include Interactify

  organize \
    self.if(:key_set_on_context, self.chain(DoThingA, ThenB, ThenC), DoDifferentThingB),
    EitherWayDoThis
end

```
### Contract validation failures
Sometimes contract validation fails at runtime as an exception. It's something unexpected and you'll have an `Interactor::Failure` sent to rollbar/sentry/honeybadger.
If the context is large it's often hard to spot what the actual problem is or where it occurred.

#### before 
```
Interactor::Failure

#<Interactor::Context output_destination="DataExportSystem", output_format=:xml, region_code="XX", custom_flag=false, process_mode="sample", cache_identifier="GenericProcessorSample-XML-XX-0", data_key="GenericProcessorSample", data_version=0, last_process_time=2023-12-26 04:00:18.953000000 GMT +00:00, process_start_time=2023-12-26 06:45:17.915237484 UTC, updated_ids=[BSON::ObjectId('123f77a58444201ff1f0611a'), BSON::ObjectId('123f78148444201fd62a2e9b'), BSON::ObjectId('12375d8084442038712ba40e')], lock_info=#<Processing::Lock _id: 123a767d7b944674cc069064, created_at: 2023-12-26 06:45:17.992417809 UTC, updated_at: 2023-12-26 06:45:17.992417809 UTC, processor: "DataExportSystem", format: "xml", type: "sample">, expired_cache_ids=[], jobs=['jobs must be filled'] items=#<Mongoid::Criteria (Interactor::Failure)
, tasks=[]>
```

#### after with call 
```
#<Interactor::Context output_destination="DataExportSystem", output_format=:xml, region_code="XX", custom_flag=false, process_mode="sample", cache_identifier="GenericProcessorSample-XML-XX-0", data_key="GenericProcessorSample", data_version=0, last_process_time=2023-12-26 04:00:18.953000000 GMT +00:00, process_start_time=2023-12-26 06:45:17.915237484 UTC, updated_ids=[BSON::ObjectId('123f77a58444201ff1f0611a'), BSON::ObjectId('123f78148444201fd62a2e9b'), BSON::ObjectId('12375d8084442038712ba40e')], lock_info=#<Processing::Lock _id: 123a767d7b944674cc069064, created_at: 2023-12-26 06:45:17.992417809 UTC, updated_at: 2023-12-26 06:45:17.992417809 UTC, processor: "DataExportSystem", format: "xml", type: "sample">, expired_cache_ids=[], tasks=['tasks must be filled'] items=#<Mongoid::Criteria (Interactor::Failure)
, tasks=[], contract_failures={:tasks=>["tasks must be filled"]}>
```

#### after with call!
```
#<SomeSpecificInteractor::ContractFailure output_destination="DataExportSystem", output_format=:xml, region_code="XX", custom_flag=false, process_mode="sample", cache_identifier="GenericProcessorSample-XML-XX-0", data_key="GenericProcessorSample", data_version=0, last_process_time=2023-12-26 04:00:18.953000000 GMT +00:00, process_start_time=2023-12-26 06:45:17.915237484 UTC, updated_ids=[BSON::ObjectId('123f77a58444201ff1f0611a'), BSON::ObjectId('123f78148444201fd62a2e9b'), BSON::ObjectId('12375d8084442038712ba40e')], lock_info=#<Processing::Lock _id: 123a767d7b944674cc069064, created_at: 2023-12-26 06:45:17.992417809 UTC, updated_at: 2023-12-26 06:45:17.992417809 UTC, processor: "DataExportSystem", format: "xml", type: "sample">, expired_cache_ids=[], tasks=['tasks must be filled'] items=#<Mongoid::Criteria (Interactor::Failure)
, tasks=[], contract_failures={:tasks=>["tasks must be filled"]}>
```

### Promising
You can annotate your interactors in the organize arguments with their promises.
This then acts as executable documentation that is validated at load time and enforced to stay in sync with the interactor.

A writer of an organizer may quite reasonably expect `LoadOrder` to promise `:order`, but for the reader, it's not always as immediately obvious
which interactor in the chain is responsible for provides which key.

```ruby
organize \
  LoadOrder.promising(:order), 
  TakePayment.promising(:payment_transaction)
```

This will be validated at load time against the interactors promises.
An example of a failure would be:

```
SomeOrganizer::DoStep1 does not promise:
step_1

Actual promises are:
step1
```


### Interactor wiring specs
Sometimes you have an interactor chain that fails because something is expected deeper down the chain and not provided further up the chain. 
The existing way to solve this is with enough integration specs to catch them, hunting and sticking a `byebug`, `debugger` or `binding.pry` in at suspected locations and inferring where in the chain the wiring went awry.

But we can do better than that if we always `promise` something that is later `expect`ed.

In order to detect these wiring issues, stick a spec in your test suite like this:

```ruby
RSpec.describe 'InteractorWiring' do
  it 'validates the interactors in the whole app', :aggregate_failures do
    errors = Interactify.validate_app(ignore: [/Priam/])

    expect(errors).to eq ''
  end
end
```

```
    Missing keys: :order_id
              in: AssignOrderToUser
             for: PlaceOrder
```

This allows you to quickly see exactly where you missed assigning something to the context.
Combine with lambda debugging `->(ctx) { byebug if ctx.order_id.nil?},` in your chains to drop into the exact
location in the chain to find where to make the change.

### RSpec matchers
Easily add [low value, low cost](https://noelrappin.com/blog/2017/02/high-cost-tests-and-high-value-tests/) specs for your expects and promises.

```ruby
expect(described_class).to expect_inputs(:order_id)
expect(described_class).to promise_outputs(:order)
```

### Sidekiq Jobs
Sometimes you want to asyncify an interactor.

```ruby
# before
class SomeInteractor
  include Interactify

  def call
    # ...
  end
end
```

```diff
- SomeInteractor.call(*args)
+ class SomeInteractorJob
+   include Sidekiq::Job
+
+   def perform(*args)
+     SomeInteractor.call(*args)
+   end
+ end
+
+ SomeInteractorJob.perform_async(*args)
```

```ruby
# after
class SomeInteractor
  include Interactify

  def call
    # ...
  end
end
```

No need to manually create a job class or handle the perform/call impedance mismatch

```diff
- SomeInteractor.call!(*args)
+ SomeInteractor::Async.call!(*args)
```

This also makes it easy to add cron jobs to run interactors. As any interactor can be asyncified.
By using it's internal Async class.

N.B. as your class is now executing asynchronously you can no longer rely on its promises later on in the chain.

## FAQs
- This is ugly isn't it?

```ruby
class OuterOrganizer
  # ... boilerplate ...
  organize \
    SetupStep,
    self.each(:ids, 
      LoadOrder, 
      ->(c){ byebug if c.order.nil? },
      DoSomethingWithOrder
    )
end
```
1. Do you find the syntax of OuterOrganizer ugly?

While the syntax might seem unconventional initially, its conceptual elegance lies in streamlining complex interactor chains. Traditional methods often involve navigating through multiple files, creating a hidden and cumbersome architecture. This gem aims to alleviate that by centralizing operations, making the overall process more intuitive.

2. Is this compatible with interactor/interactor-contracts?

Yes, it's fully compatible. We currently use these as dependencies. While there's a possibility of future changes, maintaining this compatibility is a priority.

3. Why not suggest enhancements to the interactor or interactor-contracts gems?

These gems are excellent in their own right, which is why we've built upon them. Proposing such extensive changes might not align with their current philosophy. However, if our approach proves stable and garners interest, we're open to discussing potential contributions to these gems.

4. Is this just syntactic sugar?

It's more than that. This approach enhances readability and comprehension of the code. It simplifies the structure, making it easier to navigate and maintain.

5. Is the new DSL/syntax easier to understand than plain old Ruby objects (POROs)?

This is subjective, but we believe it is. It reduces the need for numerous files addressing common interactor issues, thereby streamlining the workflow.

6. Doesn't this approach become verbose and complex in large applications?

While it may appear so, this method shines in large-scale applications with numerous interactors. It simplifies locating and modifying the necessary interactors, which is often a cumbersome process.

7. What if I prefer using Service Objects?

That's completely valid. Service Objects have their merits, but this gem is particularly useful for those deeply engaged with interactors. It capitalizes on the chaining, contracts, simplicity, composability, and testability that interactors offer. Combining Service Objects with interactors might not retain these advantages as effectively.
## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
