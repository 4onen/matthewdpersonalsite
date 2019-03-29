module GSheet exposing (Row, Table, getSheet, getSheetResponse)

import Dict exposing (Dict)
import Http
import Json.Decode as JD
import Parser exposing ((|.), (|=), Parser)


type alias Row =
    Dict String String


type alias Table =
    List Row


datasheet_url : String -> String
datasheet_url key =
    "https://spreadsheets.google.com/feeds/list/" ++ key ++ "/od6/public/basic?alt=json"


getSheet : String -> (Result Http.Error Table -> msg) -> Cmd msg
getSheet key tagger =
    Http.get
        { url = datasheet_url key
        , expect = Http.expectJson (errorSimplifier >> tagger) decoder
        }


getSheetResponse : String -> (Result Http.Error String -> msg) -> Cmd msg
getSheetResponse key tagger =
    Http.get
        { url = datasheet_url key
        , expect = Http.expectString tagger
        }


errorSimplifier : Result Http.Error (List (Result (List Parser.DeadEnd) (Dict String String))) -> Result Http.Error Table
errorSimplifier result =
    case result of
        Ok data ->
            data
                |> List.indexedMap (\i -> Tuple.pair (i + 1))
                |> List.foldl
                    (\( i, dat ) state ->
                        let
                            stringifyProblem prob =
                                case prob of
                                    Parser.Expecting str ->
                                        "I was expecting \"" ++ str ++ "\" somewhere in this row and couldn't find it!"

                                    Parser.ExpectingSymbol symb ->
                                        case symb of
                                            ":" ->
                                                "I was expecting to find a '\\:' somewhere in my parsing. Did you accidentally use ':' without the backslash?"

                                            _ ->
                                                "I was expecting to find a '" ++ symb ++ "' somewhere in this row!"

                                    Parser.ExpectingEnd ->
                                        "I was expecting the end of the data stream and didn't get it. Were there other problems?"

                                    Parser.Problem str ->
                                        "I ran into a problem best described \"" ++ str ++ "\"..."

                                    _ ->
                                        "I ran into a problem I'm not yet programmed to explain properly! D'oh!"

                            listStringToString =
                                List.intersperse ","
                                    >> List.foldl (++) ""
                                    >> (\s -> "[" ++ s ++ "]")

                            newerrstr err =
                                ("Table row " ++ String.fromInt i ++ " ")
                                    ++ (err
                                            |> List.map (.problem >> stringifyProblem)
                                            |> listStringToString
                                       )
                                    ++ "\n\n"
                        in
                        case ( dat, state ) of
                            ( Err err, Err errstr ) ->
                                Err <| errstr ++ newerrstr err

                            ( Err err, _ ) ->
                                Err <| newerrstr err

                            ( _, Err errstr ) ->
                                Err <| errstr

                            ( Ok row, Ok table ) ->
                                Ok <| row :: table
                    )
                    (Result.Ok [])
                |> Result.mapError Http.BadBody

        Err err ->
            Err err


decoder : JD.Decoder (List (Result (List Parser.DeadEnd) (Dict String String)))
decoder =
    JD.at [ "feed", "entry" ] <|
        JD.list <|
            JD.map2
                (\a b -> Result.map ((::) ( "year", a ) >> Dict.fromList) b)
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
                                |. Parser.chompWhile (\c -> c /= ',' && c /= ':' && c /= '\\')
                                |. Parser.oneOf
                                    [ Parser.symbol ","
                                    , Parser.symbol "\\:"
                                    , Parser.symbol "\\"
                                    , Parser.end
                                    ]
                        , Parser.succeed (Parser.Done ())
                        ]
                )
                |> Parser.getChompedString
                |> Parser.map (trimPostfix ",")
                |> Parser.map (String.filter ((/=) '\\'))

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
                [ Parser.succeed (Parser.Done found) |. Parser.end
                , Parser.map (\new -> Parser.Loop (new :: found)) item
                ]
        )
