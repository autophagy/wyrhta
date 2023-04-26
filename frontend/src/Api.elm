module Api exposing (ApiResource, Data(..), apiResourceDecoder)

import Http
import Json.Decode exposing (Decoder, field, int, map2, string)


type alias ApiResource =
    { id : Int
    , url : String
    }


apiResourceDecoder : Decoder ApiResource
apiResourceDecoder =
    map2 ApiResource
        (field "id" int)
        (field "url" string)


type Data value
    = Loading
    | Success value
    | Failure Http.Error
