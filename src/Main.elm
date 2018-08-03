module Main exposing (..)

import Html exposing (program)
import Element exposing (Element,el,text)
import Element.Attributes exposing (..)

import Stylesheet exposing (StyleTypes(..),stylesheet)

main = program
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

init = () ! []

update msg model = init

view model =
    Element.viewport stylesheet <|
        Element.column Page [paddingXY 20 0, height fill, width fill] 
            [ Element.el None [alignTop] (text "I'm at the top!")
            , Element.row None [spacing 20] 
                [ Element.el None [alignLeft] (text "Navigation:")
                , Element.el None [] (text "Left")
                , Element.el None [] (text "Mid")
                , Element.el None [] (text "Right")
                ]
            , Element.el None [center,height fill] (text "I'm content!")
            , Element.el None [center,alignBottom] (text "I'ma be a footer when I grow up, ma!")
            ]

subscriptions model = Sub.none
