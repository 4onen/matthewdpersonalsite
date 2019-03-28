module ViewUtil exposing (onClickNothingElse, rangeSliderWithStep, text)

import Html exposing (Html)
import Html.Attributes as A
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


rangeSliderWithStep : String -> ( Float, Float, Float ) -> Bool -> (String -> msg) -> Float -> Html.Html msg
rangeSliderWithStep name ( min, max, step ) disable onInput value =
    Html.div []
        [ Html.text name
        , Html.input
            [ A.type_ "number"
            , A.min <| String.fromFloat min
            , A.max <| String.fromFloat max
            , A.step <| String.fromFloat step
            , A.value <| String.fromFloat value
            , A.disabled disable
            , E.onInput onInput
            ]
            []
        , Html.input
            [ A.type_ "range"
            , A.min <| String.fromFloat min
            , A.max <| String.fromFloat max
            , A.step <| String.fromFloat step
            , A.value <| String.fromFloat value
            , A.value <| String.fromFloat value
            , A.disabled disable
            , E.onInput onInput
            ]
            []
        ]
