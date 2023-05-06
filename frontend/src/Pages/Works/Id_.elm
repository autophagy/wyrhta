module Pages.Works.Id_ exposing (Model, Msg, page)

import Api
import Api.Event exposing (Event)
import Api.Project exposing (Project, getProject)
import Api.State exposing (State(..))
import Api.Work exposing (Work, getWork, getWorkEvents)
import Dict exposing (Dict)
import Dict.Extra exposing (groupBy)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import Markdown.Parser as Markdown
import Markdown.Renderer
import Page exposing (Page)
import Time exposing (Month(..), posixToMillis, toDay, toMonth, toYear, utc)
import View exposing (View)


page : { id : String } -> Page Model Msg
page params =
    Page.element
        { init = init params.id
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


type alias Model =
    { workData : Api.Data Work
    , projectData : Api.Data Project
    , eventsData : Api.Data (List Event)
    }


init : String -> ( Model, Cmd Msg )
init id =
    ( { workData = Api.Loading
      , projectData = Api.Loading
      , eventsData = Api.Loading
      }
    , Cmd.batch
        [ getWork (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedWork }
        , getWorkEvents (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedEvents }
        ]
    )



-- UPDATE


type Msg
    = ApiRespondedWork (Result Http.Error Work)
    | ApiRespondedProject (Result Http.Error Project)
    | ApiRespondedEvents (Result Http.Error (List Event))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiRespondedWork (Ok work) ->
            ( { model | workData = Api.Success work }
            , getProject work.project.id { onResponse = ApiRespondedProject }
            )

        ApiRespondedWork (Err err) ->
            ( { model | workData = Api.Failure err }
            , Cmd.none
            )

        ApiRespondedProject (Ok project) ->
            ( { model | projectData = Api.Success project }
            , Cmd.none
            )

        ApiRespondedProject (Err err) ->
            ( { model | projectData = Api.Failure err }
            , Cmd.none
            )

        ApiRespondedEvents (Ok events) ->
            ( { model | eventsData = Api.Success events }
            , Cmd.none
            )

        ApiRespondedEvents (Err err) ->
            ( { model | eventsData = Api.Failure err }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


groupEvents : List Event -> Dict String (List Event)
groupEvents events =
    let
        eventToString =
            \e -> String.join "." [ String.fromInt (toYear utc e.created_at), toMonthStr (toMonth utc e.created_at), String.pad 2 '0' <| String.fromInt (toDay utc e.created_at) ]
    in
    groupBy eventToString events


toMonthStr : Month -> String
toMonthStr month =
    case month of
        Jan ->
            "01"

        Feb ->
            "02"

        Mar ->
            "03"

        Apr ->
            "04"

        May ->
            "05"

        Jun ->
            "06"

        Jul ->
            "07"

        Aug ->
            "08"

        Sep ->
            "09"

        Oct ->
            "10"

        Nov ->
            "11"

        Dec ->
            "12"


viewEvent : Event -> Html Msg
viewEvent event =
    Html.div [] [ Html.text <| "Work was " ++ stateToString event.current_state ++ "." ]


compareEvent : Event -> Event -> Order
compareEvent a b =
    compare (posixToMillis b.created_at) (posixToMillis a.created_at)


viewEvents : Dict String (List Event) -> List (Html Msg)
viewEvents events =
    let
        viewEventGroup =
            \date es htmlEvents -> Html.div [ class "event-block" ] [ Html.div [ class "event-date" ] [ Html.text date ], Html.div [] (List.map viewEvent <| List.sortWith compareEvent es) ] :: htmlEvents
    in
    Dict.foldl viewEventGroup [] events


viewNotes : String -> Html Msg
viewNotes notes =
    Html.div []
        [ case
            notes
                |> Markdown.parse
                |> Result.mapError (\d -> d |> List.map Markdown.deadEndToString |> String.join "\n")
                |> Result.andThen (\ast -> Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer ast)
          of
            Ok rendered ->
                Html.div [] rendered

            Err error ->
                Html.text error
        ]


viewWork : Work -> Project -> Html Msg
viewWork work project =
    let
        notesSection =
            case work.notes of
                Nothing ->
                    []

                Just notes ->
                    [ Html.div [ class "notes" ] [ Html.h2 [] [ Html.text "Notes" ], Html.div [] [ viewNotes notes ] ] ]
    in
    Html.div []
        [ Html.div [ class "container work-name" ]
            [ Html.h1 [] [ Html.text work.name ]
            , Html.div [] [ Html.text "Work in ", Html.a [ Html.Attributes.href ("/projects/" ++ String.fromInt project.id) ] [ Html.text project.name ], Html.text "." ]
            ]
        , Html.div [ class "container header" ] <| optionalImage work.images.header
        , Html.div [ class "container" ] (viewWorkDetails work :: notesSection)
        ]


detailRow : String -> String -> Html Msg
detailRow k v =
    Html.div [ class "detail-row" ]
        [ Html.div [ class "key" ] [ Html.text k ]
        , Html.div [ class "value" ] [ Html.text v ]
        ]


optionalDetailRow : String -> Maybe String -> List (Html Msg)
optionalDetailRow k maybeV =
    case maybeV of
        Just v ->
            [ detailRow k v ]

        Nothing ->
            []


viewWorkDetails : Work -> Html Msg
viewWorkDetails work =
    Html.div [ class "work-details" ]
        (detailRow "State" (stringCapitalize <| stateToString work.current_state.state)
            :: detailRow "Clay Body" work.clay.name
            :: optionalDetailRow "Glaze" work.glaze_description
        )


optionalImage : Maybe String -> List (Html Msg)
optionalImage url =
    case url of
        Just u ->
            [ Html.img [ Html.Attributes.src u ] [] ]

        Nothing ->
            []


stateToString : State -> String
stateToString state =
    case state of
        Thrown ->
            "thrown"

        Trimming ->
            "in trimming"

        AwaitingBisqueFiring ->
            "awaiting bisque firing"

        AwaitingGlazeFiring ->
            "awaiting glaze firing"

        Finished ->
            "finished"

        Recycled ->
            "recycled"

        _ ->
            "unknown"


stringCapitalize : String -> String
stringCapitalize word =
    String.uncons word
        |> Maybe.map (\( head, tail ) -> String.cons (Char.toUpper head) tail)
        |> Maybe.withDefault ""


view : Model -> View Msg
view model =
    let
        title =
            case model.workData of
                Api.Success work ->
                    work.name

                _ ->
                    ""

        workView =
            case ( model.workData, model.projectData ) of
                ( Api.Success work, Api.Success project ) ->
                    viewWork work project

                ( Api.Loading, _ ) ->
                    Html.div [] [ Html.text "..." ]

                ( _, Api.Loading ) ->
                    Html.div [] [ Html.text "..." ]

                ( _, Api.Failure _ ) ->
                    Html.div [] [ Html.text ":(" ]

                ( Api.Failure _, _ ) ->
                    Html.div [] [ Html.text ":(" ]

        eventsView =
            case model.eventsData of
                Api.Success events ->
                    Html.div [ class "container" ] (Html.h2 [] [ Html.text "Timeline" ] :: viewEvents (groupEvents events))

                Api.Loading ->
                    Html.div [] [ Html.text "..." ]

                Api.Failure _ ->
                    Html.div [] [ Html.text ":(" ]
    in
    { title = title
    , body = [ workView, eventsView ]
    }
