module Views.SummaryList exposing (Summary, summaryList)

import Html exposing (Html)
import Html.Attributes exposing (class)


type alias Summary =
    { thumbnail : Maybe String
    , link : String
    , title : String
    , summary : String
    }


summaryList : List Summary -> Html msg
summaryList items =
    Html.div [ class "summary-list" ] <| List.map summaryCard items


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
    Html.div [ class "summary-card" ]
        [ Html.div [ class "thumbnail" ] [ Html.img [ Html.Attributes.src image_src ] [] ]
        , Html.div [ class "summary" ]
            [ Html.a [ Html.Attributes.href item.link ] [ Html.h3 [] [ Html.text item.title ] ]
            , Html.div [] [ Html.text item.summary ]
            ]
        ]
