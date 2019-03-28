module ViewUtil exposing (onClickNothingElse,text)

import Html exposing (Html)
import Html.Events as E
import Json.Decode as JD


onClickNothingElse : msg -> Html.Attribute msg
onClickNothingElse tagger =
    E.custom "click" <|
        JD.succeed
            { message = tagger
            , stopPropagation = True
            , preventDefault = True
            }


text : String -> Html msg
text str =
    Html.p [] [ Html.text str ]
