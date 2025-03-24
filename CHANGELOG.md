# Changelog

## v1.1.0

* Add support for Elixir 1.16, 1.17 and 1.18. Drop support for Elixir 1.13, 1.14, and 1.15. Elixir >= 1.16 is now required. Dropping support for older versions of Elixir simply means that this package is no longer tested with them in CI, and that compatibility issues are not considered bugs.
* Drop support for Erlang/OTP 24, and Erlang/OTP >= 25 is now required. Dropping support for older versions of Erlang/OTP simply means that this package is not tested with them in CI, and that compatibility issues are not considered bugs.
* Require `fun_with_flags ~> 1.12`. This is not strictly required because `v1.11` will also work, but it makes it easier to ensure that both libraries are compatible with the latest Elixir and OTP.
* Add support for mobile screens. (Thanks [s3cur3](https://github.com/s3cur3), [pull/44](https://github.com/tompave/fun_with_flags_ui/pull/44))

## v1.0.0

No changes, but this package has been stable for so long that it's time to graduate to `v1`. It's possible to just upgrade from `v0.x` to `v1.0` without issues. This also makes it easier to keep the versions of this UI package and of the `fun_with_flags` package in lockstep, when `v2` is released.

## v0.9.0

* Add support for Elixir 1.14 and 1.15. Drop support for Elixir 1.11 and 1.12. Elixir >= 1.13 is now required. Dropping support for older versions of Elixir simply means that this package is no longer tested with them in CI, and that compatibility issues are not considered bugs.
* Drop support for Erlang/OTP 22 and 23, and Erlang/OTP >= 24 is now required. Dropping support for older versions of Erlang/OTP simply means that this package is not tested with them in CI, and that compatibility issues are not considered bugs.
* Addressed Plug an Logger deprecation warnings. Thank you [Ch4s3](https://github.com/Ch4s3) ([pull/27](https://github.com/tompave/fun_with_flags_ui/pull/27)) and [ryvasquez](https://github.com/ryvasquez) ([pull/31](https://github.com/tompave/fun_with_flags_ui/pull/31)) for bringing it up and addressing them.
* Addressed XSS vulnerability. (Thanks [ryanwinchester](https://github.com/ryanwinchester), [pull/29](https://github.com/tompave/fun_with_flags_ui/pull/29), plus [pull/34](https://github.com/tompave/fun_with_flags_ui/pull/34))

## v0.8.1

* Always URI-escape flag names before rendering them in web pages. ([pull/24](https://github.com/tompave/fun_with_flags_ui/pull/24)) This fixes a XSS vulnerability on the 404 page. Thank you [voltone](https://github.com/voltone) for reporting the issue privately and for discussing possible fixes, and [mmrupp](https://github.com/mmrupp) from [Cure53](https://cure53.de/) for discovering the issue.

## v0.8.0

* Add support for Elixir 1.11, 1.12, and 1.13. Drop support for Elixir 1.6, 1.7, 1.8, 1.9 and 1.10. Elixir >= 1.11 is now required. Dropping support for older versions of Elixir simply means that this package is no longer tested with them in CI, and that compatibility issues are not considered bugs.
* Drop support for Erlang/OTP 20 and 21, and Erlang/OTP >= 22 is now required. Dropping support for older versions of Erlang/OTP simply means that this package is not tested with them in CI, and that compatibility issues are not considered bugs.
* In the Flag index page, for each flag, always display the gates in a consistent order. Previously the order depended on how the data was returned by the persistent datastore. (Thanks [LostKobrakai](https://github.com/LostKobrakai), [pull/16](https://github.com/tompave/fun_with_flags_ui/pull/16))
* Require more recent versions of runtime dependencies.
* Local dev: added `credo` to CI setup.

## v0.7.2

* Also include a non-gzipped version of the Bootstrap CSS file, so that applications can still serve it when the pre-gzipped file is not supported. This was a problem in some setups where a reverse proxy would interfere with the browser requests for the CSS file, for example by setting a consertative `Accept-Enconding` request header.

## v0.7.1

* Relax `fun_with_flags` version constraint to `~> 1.1`

## v0.7.0

* Require `fun_with_flags 1.1.0`.
* Drop support for Elixir 1.4 and 1.5. Elixir >= 1.6 is now required.
* Drop support for OTP 19. OTP >= 20 is now required.

## v0.6.0

* Fixed issue with CSRF protextion blocking GET requests for the library's JS file. (Thanks [aturkewi](https://github.com/aturkewi), [pull/6](https://github.com/tompave/fun_with_flags_ui/pull/6))
* API change: now there is no need to declare `Plug.CSRFProtection` or `protect_from_forgery` in the host plug or phoenix router because this library's router handles it internally.
* The mouse cursor now looks like a pointer when hovering buttons.
* Allow to depend on Cowboy 2.

## v0.5.0

* Add support for the [`Plug.CSRFProtection`](https://hexdocs.pm/plug/1.6.2/Plug.CSRFProtection.html) plug ([`protect_from_forgery`](https://hexdocs.pm/phoenix/1.3.4/Phoenix.Controller.html#protect_from_forgery/2) in Phoenix) plug. (Thanks [aturkewi](https://github.com/aturkewi), [pull/4](https://github.com/tompave/fun_with_flags_ui/pull/4))

## v0.4.1

* Remove compile-time call to `Application.ensure_started` that was causing noisy warning during compilation. (Thanks [Gazler](https://github.com/Gazler), [pull/2](https://github.com/tompave/fun_with_flags_ui/pull/2))

## v0.4.0

* Require `fun_with_flags 1.0.0`.
* Add support for clearing boolean gates and display when a boolan gate is missing.
* Add support for the percentage gates: `percentage_of_time` and `percentage_of_actors`.

## v0.3.0

* Update `fun_with_flags` to `0.10`, which allows binary group names.
* Stop converting submitted group names to atoms.

## v0.2.0

* Updated dependencies.

## v0.1.0

* Visiting the details page for a non-exising flag will now render a 404 page, rather than displaying the details page with the flag disabled.
* Fixed an issue where atoms where being dynamically created when requesting the details page for non existing flags.
* Updated `fun_with_flags` dependency.

## v0.0.3

* Added interface to cleanly run standalone.
* Fixed some configuration issues.
* Added tests and documentation.

## v0.0.2

The library can now be mounted into a host application, for example a Phoenix app or another Plug app.

## v0.0.1

Unstable release.
The core functionality is working and it can run standalone.
