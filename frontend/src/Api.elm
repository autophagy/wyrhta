module Api exposing (ApiResource, Data(..), andThenDecode, apiResourceDecoder)

import Http
import Json.Decode exposing (Decoder, andThen, field, int, map, map2, string)


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


andThenDecode : Decoder a -> Decoder (a -> b) -> Decoder b
andThenDecode value partial =
    andThen (\p -> map p value) partial
