module Pages.Projects.Id_ exposing (Model, Msg, page)

import Api
import Api.Project exposing (Project, getProject, getProjectWorks)
import Api.State exposing (State(..))
import Api.Work exposing (Work)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Http
import Page exposing (Page)
import Time exposing (Month(..), toDay, toMonth, toYear, utc)
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
    { projectData : Api.Data Project
    , projectWorksData : Api.Data (List Work)
    }


init : String -> ( Model, Cmd Msg )
init id =
    ( { projectData = Api.Loading, projectWorksData = Api.Loading }
    , Cmd.batch
        [ getProject (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedProject }
        , getProjectWorks (Maybe.withDefault 0 (String.toInt id)) { onResponse = ApiRespondedWorks }
        ]
    )



-- UPDATE


type Msg
    = ApiRespondedProject (Result Http.Error Project)
    | ApiRespondedWorks (Result Http.Error (List Work))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiRespondedProject (Ok project) ->
            ( { model | projectData = Api.Success project }
            , Cmd.none
            )

        ApiRespondedProject (Err err) ->
            ( { model | projectData = Api.Failure err }
            , Cmd.none
            )

        ApiRespondedWorks (Ok works) ->
            ( { model | projectWorksData = Api.Success works }
            , Cmd.none
            )

        ApiRespondedWorks (Err err) ->
            ( { model | projectWorksData = Api.Failure err }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


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


viewProject : Project -> Html Msg
viewProject project =
    Html.div []
        [ Html.div [ class "container project-name" ]
            [ Html.h1 [] [ Html.text project.name ]
            , Html.div [] [ Html.text <| Maybe.withDefault "" project.description ]
            ]
        ]


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


viewWork : Work -> Html Msg
viewWork work =
    let
        transitioned_at =
            work.current_state.transitioned_at

        updated_date =
            String.join "." [ String.fromInt (toYear utc transitioned_at), toMonthStr (toMonth utc transitioned_at), String.pad 2 '0' <| String.fromInt (toDay utc transitioned_at) ]
    in
    Html.div [ class "work" ]
        [ Html.a [ Html.Attributes.href ("/works/" ++ String.fromInt work.id) ] [ Html.h3 [] [ Html.text work.name ] ]
        , Html.p [] [ Html.text "State: ", Html.text <| stringCapitalize <| stateToString work.current_state.state, Html.text ". Last updated: ", Html.text updated_date ]
        ]


viewWorks : List Work -> Html Msg
viewWorks works =
    Html.div [ class "works container" ] <| List.map viewWork works


view : Model -> View Msg
view model =
    let
        title =
            case model.projectData of
                Api.Success project ->
                    project.name

                _ ->
                    ""

        projectView =
            case model.projectData of
                Api.Success project ->
                    viewProject project

                Api.Loading ->
                    Html.div [] [ Html.text "..." ]

                Api.Failure _ ->
                    Html.div [] [ Html.text ":(" ]

        worksView =
            case model.projectWorksData of
                Api.Success works ->
                    viewWorks works

                Api.Loading ->
                    Html.div [] [ Html.text "..." ]

                Api.Failure _ ->
                    Html.div [] [ Html.text ":(" ]
    in
    { title = title
    , body = [ projectView, worksView ]
    }
