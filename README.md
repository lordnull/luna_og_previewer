# LunaOgPreviewer

A simple web app that asks other web pages what their OpenGraph preview image is.

# Build and Run

Assming you have the latest Elixir and Erlang installed, and want to just get
right to the docker:

    docker compose build
    docker compose pu

The site [`localhost:4000`](http://localhost:4000) should now be accessible.

# Expected Functionality

As you enter websites, the backend server will access that site, parse the page,
and return the preview url if found, presenting you with the image if successful.

If not, an error message is displayed.

The page will keep track of your history of requrests, and show them with
most recent request at the top. If you request the same site again, it is
brought to the top and fetched again; any in-progress attempt for that site is
aborted.

# Design Notes and Production upgrades

The final product is actually the second attempt. The first attempt was going to
persist the user's requests into a postgres database, run the fetches through a
dedicated request system, and update the user as the database change.

This was overkill, however, and the logistics to make it work was slowing me down.
Thus, I re-examined the problem and pivoted to the solution I present now.

State is not persisted across restarts. As this is a toy to show I can code, I
decided to simplify that down to bare bones.

State is persistented explicitely on a connection basis using LiveView. This
turned out to be the simplest way to manage it, using the provided Pheonix event
hooks and update callbacks. this also led to the choice to keep a list of requests
made.

The actual request is done using Erlang's `httpc` module. It's simple, and
does not add any extra dependencies. Since I built the project without anything
I knew I would not need (such as ecto or a mailer), it was the only http client
left available.

The UI is purposefully minimal. It is the abosolute bare minimum as I'm primarily
a backend developer. Some obvious fixes would be to add spacing and something to
indicate a request failed other than just the text of the error.

There are almost certainly security concerns with the design. There is no limit
on the sites, nor how many sites, a user can query. This was chosen in the name
of simplicity.

Requests are done without a supervisor system since we don't need a restart at
all for them. There is not a method for requests to exit when their corresponding
LiveView does.

Better documentation. Currently it is very light, primarily limited to this
readme and a few in-line "this is why this weird thing is here" code comments.
Some extra might be in order, however without a code review it's difficult to
say what and were.
