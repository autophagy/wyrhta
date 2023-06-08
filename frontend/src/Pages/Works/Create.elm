module Pages.Works.Create exposing (Model, Msg, page)

import Api
import Api.Clay exposing (Clay, getClays)
import Api.Project exposing (Project, getProjects)
import Api.State exposing (State(..), enumInitialState, stateToString)
import Api.Upload exposing (upload)
import Api.Work exposing (postWork)
import Auth
import Dict
import Effect exposing (Effect)
import File exposing (File)
import File.Select as Select
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


layout : Auth.User -> Model -> Layouts.Layout
layout user model =
    Layouts.Sidebar
        { sidebar = {}
        }


page : Auth.User -> Shared.Model -> Route () -> Page Model Msg
page user _ route =
    let
        projectId =
            Maybe.andThen String.toInt (Dict.get "project" route.query)
    in
    Page.new
        { init = init projectId
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (layout user)



-- INIT


type alias Model =
    { projectData : Api.Data (List Project)
    , clayData : Api.Data (List Clay)
    , projectId : Maybe Int
    , name : String
    , notes : Maybe String
    , clayId : Int
    , glazeDescription : Maybe String
    , thumbnail : Maybe String
    , header : Maybe String
    , state : State
    , updateState : Maybe (Api.Data ())
    }


init : Maybe Int -> () -> ( Model, Effect Msg )
init projectId () =
    ( { projectData = Api.Loading
      , clayData = Api.Loading
      , projectId = projectId
      , name = ""
      , notes = Nothing
      , clayId = 0
      , glazeDescription = Nothing
      , updateState = Nothing
      , thumbnail = Nothing
      , state = Thrown
      , header = Nothing
      }
    , Effect.batch
        [ Effect.sendCmd <| getProjects { onResponse = ApiRespondedProjects }
        , Effect.sendCmd <| getClays { onResponse = ApiRespondedClays }
        ]
    )



-- UPDATE


stringToState : String -> State
stringToState s =
    case s of
        "thrown" ->
            Thrown

        "handbuilt" ->
            Handbuilt

        _ ->
            Unknown


type Msg
    = ApiRespondedProjects (Result Http.Error (List Project))
    | ApiRespondedClays (Result Http.Error (List Clay))
    | ProjectIdUpdated String
    | NameUpdated String
    | NotesUpdated String
    | ClayIdUpdated String
    | GlazeDescriptionUpdated String
    | SelectNewThumbnailUpload
    | SelectedThumbnail File
    | UploadedNewThumbnail (Result Http.Error String)
    | SelectNewHeaderUpload
    | SelectedHeader File
    | UploadedNewHeader (Result Http.Error String)
    | StateUpdated String
    | CreateWork
    | ApiResponededCreateWork (Result Http.Error Int)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        ApiRespondedProjects (Ok projects) ->
            let
                projectId =
                    case model.projectId of
                        Just id ->
                            id

                        Nothing ->
                            List.head projects |> Maybe.map .id |> Maybe.withDefault 0
            in
            ( { model | projectData = Api.Success projects, projectId = Just projectId }
            , Effect.none
            )

        ApiRespondedClays (Ok clays) ->
            ( { model | clayData = Api.Success clays, clayId = Maybe.withDefault 0 <| Maybe.map .id <| List.head clays }
            , Effect.none
            )

        ProjectIdUpdated id ->
            ( { model | projectId = String.toInt id }
            , Effect.none
            )

        NameUpdated name ->
            ( { model | name = name }
            , Effect.none
            )

        NotesUpdated n ->
            let
                notes =
                    case n of
                        "" ->
                            Nothing

                        str ->
                            Just str
            in
            ( { model | notes = notes }, Effect.none )

        ClayIdUpdated id ->
            ( { model | clayId = Maybe.withDefault 0 <| String.toInt id }
            , Effect.none
            )

        GlazeDescriptionUpdated d ->
            let
                desc =
                    case d of
                        "" ->
                            Nothing

                        str ->
                            Just str
            in
            ( { model | glazeDescription = desc }
            , Effect.none
            )

        StateUpdated state ->
            ( { model | state = stringToState state }
            , Effect.none
            )

        SelectNewHeaderUpload ->
            ( model, Effect.sendCmd <| Select.file [ "image/*" ] SelectedHeader )

        SelectedHeader image ->
            ( model, Effect.sendCmd <| upload image "works/headers" { onResponse = UploadedNewHeader } )

        UploadedNewHeader (Ok url) ->
            ( { model | header = Just url }, Effect.none )

        SelectNewThumbnailUpload ->
            ( model, Effect.sendCmd <| Select.file [ "image/*" ] SelectedThumbnail )

        SelectedThumbnail image ->
            ( model, Effect.sendCmd <| upload image "works/thumbnails" { onResponse = UploadedNewThumbnail } )

        UploadedNewThumbnail (Ok url) ->
            ( { model | thumbnail = Just url }, Effect.none )

        CreateWork ->
            ( { model | updateState = Just Api.Loading }
            , Effect.sendCmd <|
                postWork
                    { project_id = Maybe.withDefault 0 model.projectId
                    , name = model.name
                    , notes = model.notes
                    , clay_id = model.clayId
                    , glaze_description = model.glazeDescription
                    , state = model.state
                    , thumbnail = model.thumbnail
                    , header = model.header
                    }
                    { onResponse = ApiResponededCreateWork }
            )

        ApiResponededCreateWork (Ok id) ->
            ( { model | updateState = Just <| Api.Success () }
            , Effect.pushRoute { path = Route.Path.Works_Id_ { id = String.fromInt id }, query = Dict.empty, hash = Nothing }
            )

        _ ->
            ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


projectToOption : String -> Project -> Html Msg
projectToOption selected project =
    Html.option [ A.value <| String.fromInt project.id, A.selected (selected == String.fromInt project.id) ] [ Html.text project.name ]


viewProjects : Model -> Html Msg
viewProjects model =
    let
        projects =
            case model.projectData of
                Api.Success p ->
                    p

                _ ->
                    []
    in
    Html.select [ E.onInput ProjectIdUpdated ] (List.map (projectToOption <| String.fromInt <| Maybe.withDefault 0 model.projectId) projects)


clayToOption : String -> Clay -> Html Msg
clayToOption selected clay =
    let
        isSelected =
            selected == String.fromInt clay.id
    in
    Html.option [ A.value <| String.fromInt clay.id, A.selected isSelected ] [ Html.text clay.name ]


viewClays : Model -> Html Msg
viewClays model =
    let
        clays =
            case model.clayData of
                Api.Success c ->
                    c

                _ ->
                    []
    in
    Html.select [ E.onInput ClayIdUpdated ] (List.map (clayToOption <| String.fromInt model.clayId) clays)


stateToOption : State -> State -> Html Msg
stateToOption selected state =
    Html.option [ A.value <| stateToString state, A.selected (selected == state) ] [ Html.text <| stateToString state ]


viewStates : Model -> Html Msg
viewStates model =
    Html.select [ E.onInput StateUpdated ] (List.map (stateToOption model.state) enumInitialState)


viewWorkDetails : Model -> Html Msg
viewWorkDetails model =
    let
        buttonText =
            case model.updateState of
                Nothing ->
                    "Create"

                Just (Api.Success _) ->
                    "Created!"

                _ ->
                    "..."
    in
    Html.div [ A.class "container" ]
        [ Html.h1 [] [ Html.text "Creating New Work" ]
        , Html.div [ A.class "settings work-settings" ]
            [ Html.div [ A.class "left" ]
                [ Html.h2 [] [ Html.text "Project" ]
                , viewProjects model
                , Html.h2 [] [ Html.text "Name" ]
                , Html.input [ A.type_ "text", A.name "work-name", A.value model.name, E.onInput NameUpdated ] []
                , Html.h2 [] [ Html.text "Notes" ]
                , Html.textarea [ A.name "work-notes", A.value <| Maybe.withDefault "" model.notes, E.onInput NotesUpdated ] []
                , Html.h2 [] [ Html.text "Clay Body" ]
                , viewClays model
                , Html.h2 [] [ Html.text "Glaze Description" ]
                , Html.input [ A.type_ "text", A.name "work-name", A.value <| Maybe.withDefault "" model.glazeDescription, E.onInput GlazeDescriptionUpdated ] []
                , Html.h2 [] [ Html.text "Initial State" ]
                , viewStates model
                ]
            , Html.div [ A.class "right" ]
                [ Html.h2 [] [ Html.text "Header" ]
                , Html.img [ A.class "image-upload header", A.src <| Maybe.withDefault "/img/placeholder-thumbnail.jpg" model.header, E.onClick SelectNewHeaderUpload ] []
                , Html.h2 [] [ Html.text "Thumbnail" ]
                , Html.img [ A.class "image-upload thumbnail", A.src <| Maybe.withDefault "/img/placeholder-thumbnail.jpg" model.thumbnail, E.onClick SelectNewThumbnailUpload ] []
                ]
            ]
        , Html.button [ E.onClick CreateWork ] [ Html.text buttonText ]
        ]


view : Model -> View Msg
view model =
    { title = Just "Creating New Work"
    , body = [ viewWorkDetails model ]
    }
