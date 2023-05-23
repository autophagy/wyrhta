module Views.SummaryList exposing (Summary, summaryList)

import Html exposing (Html)
import Html.Attributes as A


type alias Summary =
    { thumbnail : Maybe String
    , link : String
    , title : String
    , summary : String
    }


summaryList : List Summary -> Html msg
summaryList items =
    Html.div [ A.class "summary-list" ] <| List.map summaryCard items


summaryCard : Summary -> Html msg
summaryCard item =
    let
        image_src =
            case item.thumbnail of
                Nothing ->
                    "/img/placeholder-thumbnail.jpg"

                Just url ->
                    url
    in
    Html.a [ A.class "summary-card", A.href item.link ]
        [ Html.div [ A.class "thumbnail" ] [ Html.img [ A.src image_src ] [] ]
        , Html.div [ A.class "summary" ]
            [ Html.h3 [] [ Html.text item.title ]
            , Html.div [] [ Html.text item.summary ]
            ]
        ]
