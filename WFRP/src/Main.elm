module Main exposing (main)

import Browser
import Dict exposing (Dict)
import GSheet
import Html
import Html.Attributes as A
import Html.Events as E
import Http
import TimelineRegion exposing (RegionType(..), TimelineRegion)
import ViewUtil exposing (onClickNothingElse, text)


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


datasheet_key =
    "1lL9-y3zgfcmst_YMpRLVQwzONZD615SD5-FAZtpJqh8"


type alias UIModel =
    { selected : Int
    , extents : ( Float, Float )
    }


uiInit : List TimelineRegion -> UIModel
uiInit ls =
    let
        startyear =
            ls
                |> List.map (.start >> .year)
                |> List.minimum
                |> Maybe.withDefault 0

        endyear =
            ls
                |> List.map
                    (\r ->
                        case r.end of
                            Point ->
                                r.start.year

                            Region { year } ->
                                year

                            Era { year } ->
                                year
                    )
                |> List.maximum
                |> Maybe.withDefault 0
    in
    { selected = -1
    , extents = ( toFloat startyear, toFloat endyear )
    }


type Model
    = Loading
    | Loaded (List TimelineRegion) UIModel
    | Failure String


type Msg
    = Response (Result Http.Error GSheet.Table)
    | ClickOn Int
    | SlideStart Float
    | SlideEnd Float


init : () -> ( Model, Cmd Msg )
init () =
    ( Loading
    , GSheet.getSheet datasheet_key Response
    )


nocmd : a -> ( a, Cmd msg )
nocmd a =
    ( a, Cmd.none )


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    nocmd <|
        case msg of
            Response result ->
                case result of
                    Result.Ok val ->
                        case TimelineRegion.listFromSheet val of
                            Result.Ok ls ->
                                Loaded ls (uiInit ls)

                            Result.Err err ->
                                err
                                    |> List.intersperse ","
                                    |> List.foldl (++) ""
                                    |> (\s -> "[" ++ s ++ "]")
                                    |> Failure

                    Result.Err err ->
                        Failure <| stringifyHttpError err

            ClickOn i ->
                case model of
                    Loaded data ui ->
                        Loaded data { ui | selected = i }

                    _ ->
                        model

            SlideStart newStart ->
                case model of
                    Loaded data ui ->
                        Loaded data { ui | extents = ( newStart, max (newStart + 0.1) <| Tuple.second ui.extents ) }

                    _ ->
                        model

            SlideEnd newEnd ->
                case model of
                    Loaded data ui ->
                        Loaded data { ui | extents = ( min (newEnd - 0.1) <| Tuple.first ui.extents, newEnd ) }

                    _ ->
                        model


stringifyHttpError : Http.Error -> String
stringifyHttpError err =
    case err of
        Http.BadUrl str ->
            "Bad URL! \"" ++ str ++ "\""

        Http.Timeout ->
            "Timeout when trying to connect to Google Spreadsheets..."

        Http.NetworkError ->
            "The network provider changed while I was talking! Refresh?"

        Http.BadStatus i ->
            "HTTP Protocol error code " ++ String.fromInt i ++ " received."

        Http.BadBody errstr ->
            "So there were... a few parsing errors in the spreadsheet. See:\n" ++ errstr


view : Model -> Browser.Document Msg
view model =
    case model of
        Loading ->
            { title = "Loading...", body = [ Html.text "Still loading..." ] }

        Loaded parseResult ui ->
            { title = "Loaded!"
            , body =
                [ viewTimeline parseResult ui
                , rangeSliderWithStep "Start date"
                    ( 2000, 2064, 0.1 )
                    False
                    (String.toFloat
                        >> Maybe.withDefault (Tuple.first ui.extents)
                        >> SlideStart
                    )
                    (Tuple.first ui.extents)
                , rangeSliderWithStep "End date"
                    ( 2000, 2064, 0.1 )
                    False
                    (String.toFloat
                        >> Maybe.withDefault (Tuple.first ui.extents)
                        >> SlideEnd
                    )
                    (Tuple.second ui.extents)
                , (if ui.selected >= 0 then
                    List.drop ui.selected parseResult
                        |> List.head
                        |> Maybe.map viewRegion

                   else
                    Nothing
                  )
                    |> Maybe.withDefault (Html.div [] [ Html.text "Nothing selected." ])
                ]
            }

        Failure err ->
            { title = "Oops!"
            , body =
                err
                    |> String.split "\n"
                    |> List.map
                        (Html.text
                            >> List.singleton
                            >> Html.p []
                        )
            }


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


viewTimeline : List TimelineRegion -> UIModel -> Html.Html Msg
viewTimeline parseResult { selected, extents } =
    let
        yearlist =
            parseResult |> List.map (.start >> .year)

        ( minyear, maxyear ) =
            extents

        widthscalar =
            10 * 128 / (maxyear - minyear)

        timelineHeight =
            parseResult
                |> List.filter
                    (\r ->
                        case r.end of
                            Era _ ->
                                False

                            _ ->
                                True
                    )
                |> List.length
                |> (*) 10
    in
    parseResult
        |> List.indexedMap
            (\i r ->
                let
                    ( begin, end ) =
                        TimelineRegion.regionFloatExtents r

                    width =
                        10.0 + widthscalar * (end - begin)

                    borderColor =
                        if selected == i then
                            "cyan"

                        else
                            "white"
                in
                case r.end of
                    Era _ ->
                        Html.div
                            [ A.style "box-sizing" "border-box"
                            , A.style "position" "absolute"
                            , A.style "margin" "0"
                            , A.style "height" ((timelineHeight |> String.fromInt) ++ "px")
                            , A.style "width" <| String.fromFloat width ++ "px"
                            , A.style "left" <| String.fromFloat (widthscalar * (begin - minyear)) ++ "px"
                            , A.style "top" "0"
                            , onClickNothingElse <| ClickOn i
                            , A.style "background-color" "lightyellow"
                            , A.style "border" "1px solid black"
                            ]
                            []

                    _ ->
                        Html.div
                            [ A.style "box-sizing" "border-box"
                            , A.style "position" "relative"
                            , A.style "margin" "0"
                            , A.style "height" "10px"
                            , A.style "width" <| String.fromFloat width ++ "px"
                            , A.style "left" <| String.fromFloat (widthscalar * (begin - minyear)) ++ "px"
                            , onClickNothingElse <| ClickOn i
                            , A.style "background-color" "tan"
                            , A.style "border" <| "2px outset " ++ borderColor
                            , A.style "border-radius" "10px"
                            ]
                            []
            )
        |> Html.div
            [ A.style "position" "relative"
            , A.style "padding" "0"
            , A.style "margin" "0"
            , A.style "height" ((timelineHeight |> String.fromInt) ++ "px")
            , A.style "width" "100%"
            , A.style "overflow" "hidden"
            , onClickNothingElse <| ClickOn -1
            , A.style "background-color" "lightgrey"
            ]


viewRegion : TimelineRegion -> Html.Html msg
viewRegion r =
    Html.div []
        [ Html.h1 [] [ Html.text r.headline ]
        , text (r.text |> Maybe.withDefault "No description.")
        , text ("Year: " ++ String.fromInt r.start.year)
        , text ("Month: " ++ (r.start.month |> Maybe.map String.fromInt |> Maybe.withDefault "None"))
        , text ("Day: " ++ (r.start.day |> Maybe.map String.fromInt |> Maybe.withDefault "None"))
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
