module SplatJson exposing (main)

import Browser
import GSheet
import Html


type alias Model =
    Maybe String


datasheet_key =
    "1lL9-y3zgfcmst_YMpRLVQwzONZD615SD5-FAZtpJqh8"


main =
    Browser.document
        { init = \() -> ( Nothing, GSheet.getSheetResponse datasheet_key identity )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }


update response _ =
    Tuple.pair
        (case response of
            Result.Ok dat ->
                Just dat

            Result.Err err ->
                Just (Debug.toString err)
        )
        Cmd.none


view model =
    case model of
        Nothing ->
            { title = "Loading..."
            , body = [ Html.text "Waiting for a response from GSheets" ]
            }

        Just dat ->
            { title = "Displayed."
            , body = [ Html.text dat ]
            }
