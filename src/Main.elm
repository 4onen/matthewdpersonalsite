module Main exposing (..)

import Html
import Browser
import Element exposing (Element,el,text)
import Element.Attributes exposing (..)
import Style

main = Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

init () = ((),Cmd.none)

update msg model = init ()

view model =
    Element.viewport styleSheet <|
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

type Style = Page | None

styleSheet =
    Style.styleSheet
        [ Style.style Page 
            []
        ]

subscriptions model = Sub.none
