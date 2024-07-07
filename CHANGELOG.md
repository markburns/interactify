## [Unreleased]
- Add support for `Interactify.with(queue: 'within_30_seconds', retry: 3)`
- Fix issue with anonymous classes not being able to be used in chains

## [0.5.0] - 2024-01-01
- Add support for `SetA = Interactify { _1.a = 'a' }`, lambda and block class creation syntax
- Add support for organizing `organize A.organizing(B, C, D), E, F` contract syntax
- make definition errors raise optionally
- raise an error with unexpected keys in Interactify.if clause
- propagate caller_info through chains

## [0.4.1] - 2023-12-29
- Fix bug triggered when nesting each and if

## [0.4.0] - 2023-12-29
- All internal restructuring/refactoring into domains. 
- Add support for organize `self.if(:condition, then: A, else: B)` syntax
- change location of matchers to `require 'interactify/rspec_matchers/matchers'`

## [0.3.0-RC1] - 2023-12-29
- Fixed to work with and make optional dependencies for sidekiq and railties. Confirmed as working with ruby >= 3.1.4

## [0.3.0-alpha.2] - 2023-12-29
- Remove deep_matching development dependency


## [0.3.0-alpha.1] - 2023-12-29
- Added support for `{if: :condition, then: A, else: B}` in organizers

## [0.2.0-alpha.1] - 2023-12-27
- Added support for Interactify.promising syntax in organizers

## [0.1.0-alpha.1] - 2023-12-16
- Initial release
