module Timeline exposing (Msg, Timeline, fromSheet, update, view)

import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import TimelineRegion exposing (RegionType(..), TimelineRegion)
import ViewUtil exposing (onClickNothingElse, rangeSliderWithStep, text)


type alias UIModel =
    { selected : Int
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
    = ClickOn Int
    | SlideStart Float
    | SlideEnd Float


fromSheet : List (Dict String String) -> Result (List String) Timeline
fromSheet sheet =
    Result.map2
        (\times titles ->
            { titles = titles
            , times = times
            , ui = uiInit times
            }
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


update : Msg -> Timeline -> Timeline
update msg timeline =
    { timeline | ui = updateHelper msg timeline timeline.ui }


updateHelper : Msg -> Timeline -> UIModel -> UIModel
updateHelper msg timeline ui =
    case msg of
        ClickOn i ->
            { ui | selected = i }

        SlideStart newStart ->
            { ui | extents = ( newStart, max (newStart + 0.1) <| Tuple.second ui.extents ) }

        SlideEnd newEnd ->
            { ui | extents = ( min (newEnd - 0.1) <| Tuple.first ui.extents, newEnd ) }


view : Timeline -> Html Msg
view timeline =
    Html.div []
        [ viewDiagram timeline.times timeline.ui
        , viewControls timeline
        , viewSelected timeline
        ]


viewDiagram : List TimelineRegion -> UIModel -> Html.Html Msg
viewDiagram times { selected, extents } =
    let
        yearlist =
            times |> List.map (.start >> .year)

        ( minyear, maxyear ) =
            extents

        widthscalar =
            10 * 128 / (maxyear - minyear)

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
                            [ Html.i [ A.style "position" "absolute", A.style "bottom" "0" ] [ Html.text r.headline ] ]

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


viewControls : Timeline -> Html Msg
viewControls timeline =
    Html.div []
        [ rangeSliderWithStep "Start date"
            ( 2000, 2064, 0.1 )
            False
            (String.toFloat
                >> Maybe.withDefault (Tuple.first timeline.ui.extents)
                >> SlideStart
            )
            (Tuple.first timeline.ui.extents)
        , rangeSliderWithStep "End date"
            ( 2000, 2064, 0.1 )
            False
            (String.toFloat
                >> Maybe.withDefault (Tuple.first timeline.ui.extents)
                >> SlideEnd
            )
            (Tuple.second timeline.ui.extents)
        ]


viewSelected : Timeline -> Html Msg
viewSelected timeline =
    (if timeline.ui.selected >= 0 then
        timeline.times
            |> List.drop timeline.ui.selected
            |> List.head
            |> Maybe.map TimelineRegion.view

     else
        timeline.titles
            |> List.drop (-timeline.ui.selected - 1)
            |> List.head
            |> Maybe.map
                (\r ->
                    Html.div []
                        [ Html.h2 [] [ Html.text r.headline ]
                        , Html.p [] [ Html.text (r.text |> Maybe.withDefault "No title card description text!") ]
                        ]
                )
    )
        |> Maybe.withDefault (Html.div [] [ Html.text "Nothing selected!" ])
