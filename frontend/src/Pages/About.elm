module Pages.About exposing (Model, Msg, page)

import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes as A
import Markdown.Parser as Markdown
import Markdown.Renderer
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)
import Views.Footer exposing (footer)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init () =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = ExampleMsgReplaceMe


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ExampleMsgReplaceMe ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


bio : String
bio =
    """
Wes hāl! I am Mika, an amateur ceramicist based in Berlin. This site is a tool to
catalog, track and showcase my ongoing ceramic works.

I tend towards utlity and tableware pieces, with an emphasis on angular forms,
exposed clay and simple glazing. These days I'm mostly working on practicing
throwing consistently, but have started taking requests from friends for specific
pieces.

I do my work at [Ceramic Kingdom](https://www.ceramickingdomberlin.com/), in Neukölln.
You can find me elsewhere on the [Fediverse](https://hordburh.autophagy.io/@mika) or
on [Github](https://github.com/autophagy).
"""


viewBio : Html Msg
viewBio =
    Html.div []
        [ case
            bio
                |> Markdown.parse
                |> Result.mapError (\d -> d |> List.map Markdown.deadEndToString |> String.join "\n")
                |> Result.andThen (\ast -> Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer ast)
          of
            Ok rendered ->
                Html.div [] rendered

            Err error ->
                Html.text error
        ]


view : Model -> View Msg
view model =
    { title = Just "About"
    , body = [ Html.div [ A.class "container about" ] [ Html.img [ A.src "/img/me.jpg" ] [], viewBio ], footer ]
    }
