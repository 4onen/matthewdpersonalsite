module Timeline exposing (Msg, Timeline, fromSheet, update, view)

import Browser.Dom
import Browser.Events
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Html.Parser
import Html.Parser.Util
import Json.Decode as JD
import Task
import TimelineRegion exposing (RegionType(..), TimelineRegion)
import ViewUtil exposing (onClickNothingElse, rangeSliderWithStep, text)


type alias UIModel =
    { selected : Int
    , diagramWidth : Float
    , extents : ( Float, Float )
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
    | SlideStart Float
    | SlideEnd Float
    | Resize Float
    | CheckResize


timelineID =
    "Timeline"


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
    let
        ( floatStart, floatEnd ) =
            floatExtents ls

        ( startYear, endYear ) =
            ( floor floatStart, ceiling floatEnd )
    in
    { selected = -1
    , diagramWidth = 1024
    , extents = ( toFloat startYear, toFloat endYear )
    }


getDiagramWidth : Cmd Msg
getDiagramWidth =
    timelineID
        |> Browser.Dom.getElement
        |> Task.attempt (Result.map (.element >> .width) >> Result.withDefault 1024 >> Resize)


floatExtents : List TimelineRegion -> ( Float, Float )
floatExtents =
    List.foldl
        (\r maybeExtents ->
            case maybeExtents of
                Nothing ->
                    Just <| TimelineRegion.floatExtents r

                Just ( least, greatest ) ->
                    let
                        ( rbegin, rend ) =
                            TimelineRegion.floatExtents r
                    in
                    Just ( min rbegin least, max rend greatest )
        )
        Nothing
        >> Maybe.withDefault ( 0, 0 )


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

        SlideStart newStart ->
            ( { ui | extents = ( newStart, max (newStart + 0.1) <| Tuple.second ui.extents ) }, Cmd.none )

        SlideEnd newEnd ->
            ( { ui | extents = ( min (newEnd - 0.1) <| Tuple.first ui.extents, newEnd ) }, Cmd.none )

        Resize newWidth ->
            ( { ui | diagramWidth = newWidth }, Cmd.none )

        CheckResize ->
            ( ui, getDiagramWidth )


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
        yearlist =
            times |> List.map (.start >> .year)

        ( minyear, maxyear ) =
            extents

        widthscalar =
            diagramWidth / (maxyear - minyear)

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
                |> (+) 1
                |> (*) 10
    in
    times
        |> List.indexedMap
            (\i r ->
                let
                    ( begin, end ) =
                        TimelineRegion.floatExtents r

                    width =
                        10.0 + widthscalar * (end - begin)
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
                            , A.style "height" "10px"
                            , A.style "width" <| String.fromFloat width ++ "px"
                            , A.style "left" <| String.fromFloat (widthscalar * (begin - minyear)) ++ "px"
                            , onClickNothingElse <| Select i
                            , A.style "background-color" "tan"
                            , A.style "border" <|
                                if selected == i then
                                    "1px outset cyan"

                                else
                                    "2px outset white"
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
        ( firstyear, lastyear ) =
            floatExtents timeline.times
    in
    Html.div []
        [ rangeSliderWithStep "Start date"
            ( firstyear, lastyear, 0.1 )
            False
            (String.toFloat
                >> Maybe.withDefault (Tuple.first timeline.ui.extents)
                >> SlideStart
            )
            (Tuple.first timeline.ui.extents)
        , rangeSliderWithStep "End date"
            ( firstyear, lastyear, 0.1 )
            False
            (String.toFloat
                >> Maybe.withDefault (Tuple.first timeline.ui.extents)
                >> SlideEnd
            )
            (Tuple.second timeline.ui.extents)
        , Html.button [ E.onClick (Select <| timeline.ui.selected - 1) ] [ Html.text "Previous << " ]
        , Html.button [ E.onClick (Select <| timeline.ui.selected + 1) ] [ Html.text " >> Next" ]
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
                            ( r.headline, r.text, Just <| TimelineRegion.toTimeString r )
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
