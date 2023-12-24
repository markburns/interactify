# Interactify

Interactors are a great way to encapsulate business logic in a Rails application. 
However, sometimes in complex interactor chains, the complex debugging happens at one level up from your easy to read and test interactors.

Interactify wraps the interactor and interactor-contract gem and provides additional functionality making chaining and understanding interactor chains easier.

### Syntactic Sugar

```ruby
# before

class LoadOrder
  include Interactor
  include Interactor::Contracts

  expects do
    required(:id).filled
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

  expect :id
  promise :order

  def call
    context.order = Order.find(id)
  end
end
```


### Lambdas

With vanilla interactors, it's not possible to use lambdas in organizers, and sometimes we only want a lambda.
So we added support.

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
It was complex procedural code and is now broken into neat SRP classes (Single Responsibility Principle). 
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

### Conditionals (if/else)

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

class DoThingA
  # ... boilerplate ...
  def call
    # ...
  end
end

class DoThingB
  # ... boilerplate ...
  def call
    # ...
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

```

### More Conditionals 

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

Yes I agree. It's early days and I'm open to syntax improvement ideas. This is really about it being conceptually less ugly than the alternative, which is to jump around between lots of files. In the existing alternative to using this gem the ugliness is not within each individual file, but within the overall hidden architecture and the hunting process of jumping around in complex interactor chains. We can't see that ugliness but we probably experience it. If you don't feel or experience that ugliness then this gem may not be the right fit for you.


- Is this interactor/interactor-contracts compatible? 
Yes and we use them as dependencies. It's possible we'd drop those dependencies in the future but unlikely. I think it's highly likely we'd retain compatibility.


- Why not propose changes to the interactor or interactor-contracts gem?
Honestly, I think both are great and why we've built on top of them. 
I presume they'd object to such an extensive opinionated change, and I think that would be the right decision too.
If this becomes more stable, less coupled to Rails, there's interest, and things we can provide upstream I'd be happy to propose changes to those gems.

- Isn't this all just syntactic sugar?
Yes, but it's sugar that makes the code easier to read and understand.

- Is it really easier to parse this new DSL/syntax than POROs?
That's subjective, but I think so. The benefit is you have fewer extraneous files patching over a common problem in interactors.

- But it gets really verbose and complex!
Again this is subjective, but if you've worked with apps with hundred or thousands of interactors, you'll have encountered these problems.
I think when we work with interactors we're in one of two modes. 
Hunting to find the interactor we need to change, or working on the interactor we need to change.
This makes the first step much easier. 
The second step has always been a great experience with interactors.

- I prefer Service Objects
If you're not heavily invested into interactors this may not be for you.
I love the chaining interactors provide. 
I love the contracts. 
I love the simplicity of the interface.
I love the way they can be composed. 
I love the way they can be tested.
When I've used service objects, I've found them to be more complex to test and compose.
I can't see a clean way that using service objects to compose interactors could work well without losing some of the aforementioned benefits.

### TODO
We want to add support for explicitly specifying promises in organizers. The benefit here is on clarifying the contract between organizers and interactors.
A writer of an organizer may expect LoadOrder to promise :order, but for the reader, it's not quite as explicit.
The expected syntax will be

```ruby
organize \
  LoadOrder.promising(:order), 
  TakePayment.promising(:payment_transaction)
```

This will be validated at test time against the interactors promises.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

    $ bundle add UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install UPDATE_WITH_YOUR_GEM_NAME_PRIOR_TO_RELEASE_TO_RUBYGEMS_ORG

## Usage

```ruby
# e.g. in spec/supoort/interactify.rb
require 'interactify/rspec/matchers'

Interactify.configure do |config|
  config.root = Rails.root '/app'
end

Interactify.on_contract_breach do |context, attrs|
  # maybe add context to Sentry or Honeybadger etc here
end

Interactify.before_raise do |exception|
  # maybe add context to Sentry or Honeybadger etc here
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/interactify.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
