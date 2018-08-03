module Stylesheet exposing (stylesheet, StyleTypes(..))

import Style exposing (style,styleSheet)
import Style.Color as Color
import Color exposing (..)

type StyleTypes
    = None
    | Page

stylesheet = styleSheet 
    [ style Page
        [ Color.background white
        ]
    ]
