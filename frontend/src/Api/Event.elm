module Api.Event exposing (Event, compareEvent, eventsDecoder, getEvents, getEventsWithLimit)

import Api exposing (ApiResource, apiResourceDecoder)
import Api.State exposing (State, stateDecoder)
import Http
import Json.Decode exposing (Decoder, field, int, map5, maybe)
import Json.Decode.Extra exposing (datetime)
import Time exposing (Posix, posixToMillis)


type alias Event =
    { id : Int
    , work : ApiResource
    , previous_state : Maybe State
    , current_state : State
    , created_at : Posix
    }


compareEvent : Event -> Event -> Order
compareEvent a b =
    compare (posixToMillis b.created_at) (posixToMillis a.created_at)


getEvents : { onResponse : Result Http.Error (List Event) -> msg } -> Cmd msg
getEvents options =
    Http.get
        { url = "http://localhost:8000/events"
        , expect = Http.expectJson options.onResponse eventsDecoder
        }


getEventsWithLimit : Int -> { onResponse : Result Http.Error (List Event) -> msg } -> Cmd msg
getEventsWithLimit limit options =
    Http.get
        { url = "http://localhost:8000/events?limit=" ++ String.fromInt limit
        , expect = Http.expectJson options.onResponse eventsDecoder
        }


eventsDecoder : Decoder (List Event)
eventsDecoder =
    Json.Decode.list eventDecoder


eventDecoder : Decoder Event
eventDecoder =
    map5 Event
        (field "id" int)
        (field "work" apiResourceDecoder)
        (field "previous_state" (maybe stateDecoder))
        (field "current_state" stateDecoder)
        (field "created_at" datetime)
