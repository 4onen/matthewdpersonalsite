module Timeline exposing (Msg, Timeline, fromSheet, update, view)

import Browser.Dom
import Browser.Events
import Calendar
import DateTime
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Parser
import Html.Parser.Util
import Json.Decode as JD
import MyDateTime exposing (DateTime)
import Task
import Time exposing (Posix)
import TimelineRegion exposing (RegionType(..), TimelineRegion)
import ViewUtil exposing (onClickNothingElse, rangeSliderWithStep, text)


type alias UIModel =
    { selected : Int
    , diagramWidth : Float
    , extents : ( Calendar.Date, Calendar.Date )
    }


type alias TitleCard =
    { headline : String
    , text : Maybe String
    }


type alias Timeline =
    { titles : List TitleCard
    , times : List TimelineRegion
    , ui : UIModel
    }


type Msg
    = Select Int
    | MoveStart Calendar.Date
    | MoveEnd Calendar.Date
    | Resize Float
    | CheckResize
    | NoOp


timelineID =
    "Timeline"


timelineItemSizePx =
    20


defaultDate =
    Calendar.fromPosix (Time.millisToPosix 0)


defaultDateTime =
    DateTime.fromPosix (Time.millisToPosix 0)


fromSheet : List (Dict String String) -> Result (List String) ( Timeline, Cmd Msg )
fromSheet sheet =
    Result.map2
        (\times titles ->
            ( { titles = titles
              , times = times
              , ui = uiInit times
              }
            , getDiagramWidth
            )
        )
        (TimelineRegion.listFromSheet sheet)
        (sheet
            |> List.map
                (\r ->
                    case Dict.get "type" r of
                        Just "title" ->
                            case Dict.get "headline" r of
                                Just str ->
                                    Result.Ok <|
                                        Just <|
                                            { headline = str
                                            , text = Dict.get "text" r
                                            }

                                Nothing ->
                                    Result.Err "Row #: Title card headline missing!"

                        _ ->
                            Result.Ok Nothing
                )
            |> List.foldl
                (\i o ->
                    case ( i, o ) of
                        ( Err err, Err errlist ) ->
                            Err <| ("Row #: " ++ err) :: errlist

                        ( Err err, _ ) ->
                            Err [ "Row #: " ++ err ]

                        ( Ok _, Err errlist ) ->
                            Err errlist

                        ( Ok dat, Ok datlist ) ->
                            Ok <| dat :: datlist
                )
                (Result.Ok [])
            |> Result.map (List.filterMap identity)
        )


uiInit : List TimelineRegion -> UIModel
uiInit ls =
    { selected = -1
    , diagramWidth = 1024
    , extents =
        case dateExtents ls of
            Just dates ->
                dates
                    |> Tuple.mapBoth
                        MyDateTime.getDate
                        MyDateTime.getDate

            Nothing ->
                ( defaultDate
                , defaultDate
                )
    }


getDiagramWidth : Cmd Msg
getDiagramWidth =
    timelineID
        |> Browser.Dom.getElement
        |> Task.attempt (Result.map (.element >> .width) >> Result.withDefault 1024 >> Resize)


dateExtents : List TimelineRegion -> Maybe ( DateTime, DateTime )
dateExtents =
    List.foldl
        (\r maybeExtents ->
            case maybeExtents of
                Nothing ->
                    Just <| TimelineRegion.dateExtents r

                Just ( begin, end ) ->
                    let
                        ( nbegin, nend ) =
                            TimelineRegion.dateExtents r
                    in
                    Just
                        ( case MyDateTime.compare nbegin begin of
                            LT ->
                                nbegin

                            _ ->
                                begin
                        , case MyDateTime.compare nend end of
                            GT ->
                                nend

                            _ ->
                                end
                        )
        )
        Nothing


update : Msg -> Timeline -> ( Timeline, Cmd Msg )
update msg timeline =
    let
        ( newui, cmd ) =
            updateHelper msg timeline timeline.ui
    in
    ( { timeline | ui = newui }, cmd )


updateHelper : Msg -> Timeline -> UIModel -> ( UIModel, Cmd Msg )
updateHelper msg timeline ui =
    case msg of
        Select i ->
            ( { ui
                | selected =
                    Basics.clamp
                        (Basics.negate <| List.length timeline.titles)
                        (List.length timeline.times - 1)
                        i
              }
            , Cmd.none
            )

        MoveStart newStart ->
            let
                ( begin, end ) =
                    ui.extents
            in
            ( { ui
                | extents =
                    ( if Calendar.compare newStart end == LT then
                        newStart

                      else
                        begin
                    , end
                    )
              }
            , Cmd.none
            )

        MoveEnd newEnd ->
            let
                ( begin, end ) =
                    ui.extents
            in
            ( { ui
                | extents =
                    ( begin
                    , if Calendar.compare newEnd begin == GT then
                        newEnd

                      else
                        end
                    )
              }
            , Cmd.none
            )

        Resize newWidth ->
            ( { ui | diagramWidth = newWidth }, Cmd.none )

        CheckResize ->
            ( ui, getDiagramWidth )

        NoOp ->
            ( ui, Cmd.none )


view : Timeline -> Html Msg
view timeline =
    Html.div []
        [ viewDiagram timeline.times timeline.ui
        , viewControls timeline
        , viewSelected timeline
        ]


viewDiagram : List TimelineRegion -> UIModel -> Html.Html Msg
viewDiagram times { selected, diagramWidth, extents } =
    let
        ( beginExt, endExt ) =
            extents

        ( beginMil, endMil ) =
            ( Calendar.toMillis beginExt
            , Calendar.toMillis endExt
            )

        widthscalar =
            (diagramWidth - timelineItemSizePx) / (toFloat endMil - toFloat beginMil)

        timelineHeight =
            times
                |> List.filter
                    (\r ->
                        case r.end of
                            Era _ ->
                                False

                            _ ->
                                True
                    )
                |> List.length
                |> (*) timelineItemSizePx
                |> (+) 12
    in
    times
        |> List.indexedMap
            (\i r ->
                let
                    ( begin, end ) =
                        TimelineRegion.dateExtents r
                            |> Tuple.mapBoth
                                MyDateTime.toMillis
                                MyDateTime.toMillis

                    width =
                        timelineItemSizePx + widthscalar * toFloat (end - begin)

                    left =
                        widthscalar * toFloat (begin - beginMil)
                in
                case r.end of
                    Era _ ->
                        Html.div
                            [ A.style "box-sizing" "border-box"
                            , A.style "position" "absolute"
                            , A.style "margin" "0"
                            , A.style "height" ((timelineHeight |> String.fromInt) ++ "px")
                            , A.style "width" <| String.fromFloat width ++ "px"
                            , A.style "left" <| String.fromFloat left ++ "px"
                            , A.style "top" "0"
                            , onClickNothingElse <| Select i
                            , A.style "background-color" <|
                                if selected == i then
                                    "cyan"

                                else
                                    "lightyellow"
                            , A.style "border" "1px solid black"
                            ]
                            [ Html.i [ A.style "position" "absolute", A.style "bottom" "0" ] [ Html.text r.headline ] ]

                    _ ->
                        Html.div
                            [ A.style "box-sizing" "border-box"
                            , A.style "position" "relative"
                            , A.style "margin" "0"
                            , A.style "height" <| String.fromInt timelineItemSizePx ++ "px"
                            , A.style "width" <| String.fromFloat width ++ "px"
                            , A.style "left" <| String.fromFloat left ++ "px"
                            , onClickNothingElse <| Select i
                            , A.style "background-color" "tan"
                            , A.style "border" <|
                                if selected == i then
                                    "3px outset cyan"

                                else
                                    "4px outset white"
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
            , onClickNothingElse <| Select -1
            , A.style "background-color" "lightgrey"
            , A.id "Timeline"
            , E.on "resize" (JD.succeed CheckResize)
            ]


viewControls : Timeline -> Html Msg
viewControls timeline =
    let
        ( begin, end ) =
            dateExtents timeline.times
                |> Maybe.map (Tuple.mapBoth MyDateTime.getDate MyDateTime.getDate)
                |> Maybe.withDefault ( defaultDate, defaultDate )

        ( firstyear, lastyear ) =
            ( begin
                |> Calendar.toMillis
                |> Basics.toFloat
            , end
                |> Calendar.toMillis
                |> Basics.toFloat
            )

        ( uibegin, uiend ) =
            timeline.ui.extents
    in
    Html.div []
        [ Html.button [ E.onClick CheckResize ] [ Html.text "Resize Timeline" ]
        , Html.div []
            [ Html.button [ E.onClick (Select <| timeline.ui.selected - 1) ] [ Html.text "<< Previous" ]
            , Html.button [ E.onClick (Select <| timeline.ui.selected + 1) ] [ Html.text "Next >>" ]
            ]
        ]


viewSelected : Timeline -> Html Msg
viewSelected timeline =
    let
        ( headline, maybeText, maybeTimeString ) =
            (if timeline.ui.selected >= 0 then
                timeline.times
                    |> List.drop timeline.ui.selected
                    |> List.head
                    |> Maybe.map
                        (\r ->
                            ( r.headline, r.text, Just <| TimelineRegion.toTimeRangeString r )
                        )

             else
                timeline.titles
                    |> List.drop (-timeline.ui.selected - 1)
                    |> List.head
                    |> Maybe.map (\r -> ( r.headline, r.text, Nothing ))
            )
                |> Maybe.withDefault ( "SELECTION_ERROR", Just "SELECTION_ERROR", Nothing )

        headlineHtml =
            Html.Parser.run headline |> Result.map Html.Parser.Util.toVirtualDom |> Result.withDefault [ Html.text headline ]

        textHtml =
            case maybeText of
                Just str ->
                    str
                        |> Html.Parser.run
                        |> Result.map Html.Parser.Util.toVirtualDom
                        |> Result.withDefault [ Html.text str ]

                Nothing ->
                    [ Html.text "" ]
    in
    Html.div []
        [ Html.h2 [] headlineHtml
        , Html.h3 [] [ Html.text (maybeTimeString |> Maybe.withDefault "") ]
        , Html.p [] textHtml
        ]
