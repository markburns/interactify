## [Unreleased]

## [0.1.0-alpha.1] - 2023-12-16

- Initial release

## [0.2.0-alpha.1] - 2023-12-27

- Added support for Interactify.promising syntax in organizers

## [0.3.0-alpha.1] - 2023-12-29

- Added support for `{if: :condition, then: A, else: B}` in organizers

## [0.3.0-alpha.2] - 2023-12-29

- Remove deep_matching development dependency

## [0.3.0-RC1] - 2023-12-29

- Fixed to work with and make optional dependencies for sidekiq and railties. Confirmed as working with ruby >= 3.1.4

## [0.4.0-RC1] - 2023-12-29

- All internal restructuring/refactoring into domains. 
- Add support for organize `self.if(:condition, then: A, else: B)` syntax
