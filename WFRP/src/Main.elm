module Main exposing (main)

import Browser
import Html
import Http
import Json.Decode as JD
import Parser exposing ((|.), (|=), Parser)


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


datasheet_key =
    "1lL9-y3zgfcmst_YMpRLVQwzONZD615SD5-FAZtpJqh8"


datasheet_url =
    "https://spreadsheets.google.com/feeds/list/" ++ datasheet_key ++ "/od6/public/basic?alt=json"


type Model
    = Loading
    | Loaded (List (Result (List Parser.DeadEnd) (List ( String, String ))))
    | Failure String


type Msg
    = Response (Result Http.Error (List (Result (List Parser.DeadEnd) (List ( String, String )))))


init : () -> ( Model, Cmd Msg )
init () =
    ( Loading
    , Http.get
        { url = datasheet_url
        , expect = Http.expectJson Response decoder
        }
    )


decoder : JD.Decoder (List (Result (List Parser.DeadEnd) (List ( String, String ))))
decoder =
    JD.at [ "feed", "entry" ] <|
        JD.list <|
            JD.map2
                (\a b -> Result.map ((::) ( "year", a )) b)
                (JD.at [ "title", "$t" ] JD.string)
                (JD.map (Parser.run rowParser) <| JD.at [ "content", "$t" ] JD.string)


rowParser : Parser.Parser (List ( String, String ))
rowParser =
    let
        itemStart : Parser.Parser String
        itemStart =
            Parser.getChompedString (Parser.chompWhile Char.isLower)
                |. Parser.symbol ":"

        trimPostfix postfix s =
            if String.endsWith postfix s then
                String.dropRight (String.length postfix) s

            else
                s

        itemContent : Parser.Parser String
        itemContent =
            Parser.loop ()
                (\() ->
                    Parser.oneOf
                        [ Parser.succeed (Parser.Done ())
                            |. Parser.end
                        , Parser.backtrackable <|
                            Parser.succeed (Parser.Loop ())
                                |. Parser.chompWhile (\c -> c /= ',' && c /= ':')
                                |. Parser.oneOf [ Parser.symbol ",", Parser.end ]
                        , Parser.succeed (Parser.Done ())
                        ]
                )
                |> Parser.getChompedString
                |> Parser.map (trimPostfix ",")

        item : Parser.Parser ( String, String )
        item =
            Parser.succeed Tuple.pair
                |= itemStart
                |. Parser.spaces
                |= itemContent
                |. Parser.spaces
    in
    Parser.loop []
        (\found ->
            Parser.oneOf
                [ Parser.succeed (Parser.Done found)
                    |. Parser.end
                , Parser.map (\new -> Parser.Loop (new :: found))
                    item
                ]
        )


nocmd : a -> ( a, Cmd msg )
nocmd a =
    ( a, Cmd.none )


update : Msg -> Model -> ( Model, Cmd msg )
update (Response result) _ =
    nocmd <|
        case result of
            Result.Ok val ->
                Loaded val

            Result.Err err ->
                Failure <| Debug.toString err


view : Model -> Browser.Document Msg
view model =
    case model of
        Loading ->
            { title = "Loading...", body = [ Html.text "Still loading..." ] }

        Loaded parseresult ->
            { title = "Loaded!"
            , body =
                parseresult
                    |> List.map
                        (\row ->
                            case row of
                                Ok data ->
                                    viewTable data

                                Err err ->
                                    err
                                        |> Debug.toString
                                        |> Html.text
                                        |> List.singleton
                                        |> Html.div []
                        )
            }

        Failure err ->
            { title = "Oops!", body = [ Html.text err ] }


viewTable : List ( String, String ) -> Html.Html msg
viewTable =
    List.map
        (\( a, b ) ->
            [ a, b ]
                |> List.map (Html.text >> List.singleton >> Html.td [])
                |> Html.tr []
        )
        >> Html.table []


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
