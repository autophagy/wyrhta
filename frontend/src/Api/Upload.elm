module Api.Upload exposing (upload)

import File
import Http


upload : File.File -> String -> { onResponse : Result Http.Error String -> msg } -> Cmd msg
upload image key options =
    Http.request
        { method = "POST"
        , url = "http://localhost:8000/upload"
        , body = Http.multipartBody [ Http.filePart key image ]
        , expect = Http.expectString options.onResponse
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }
