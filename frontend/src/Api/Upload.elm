module Api.Upload exposing (upload)

import Api exposing (Route(..))
import File
import Http


upload : File.File -> String -> { onResponse : Result Http.Error String -> msg } -> Cmd msg
upload image key options =
    Api.post
        { route = [ Upload ]
        , body = Http.multipartBody [ Http.filePart key image ]
        , expect = Http.expectString options.onResponse
        }
