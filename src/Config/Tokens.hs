module Config.Tokens
  ( Token(..)
  , PosToken(..)
  , layoutPass
  ) where

import Data.Text (Text)

data PosToken = PosToken
  { posLine   :: Int
  , posColumn :: Int
  , posToken  :: Token
  }
  deriving (Show)

data Token
  = Section Text
  | String Text
  | Bullet
  | Comma
  | Number Int Integer
  | OpenList
  | CloseList
  | OpenMap
  | CloseMap
  | Yes
  | No

  | Error

  -- "Virtual" tokens used by the subsequent layout processor
  | LayoutSep
  | LayoutEnd
  | EOF
  deriving (Show)

-- | Process a list of position-annotated tokens inserting
-- layout end tokens as appropriate.
layoutPass ::
  [PosToken] {- ^ tokens without layout markers -} ->
  [PosToken] {- ^ tokens with    layout markers -}
layoutPass toks = foldr step (\_ -> []) toks [-1]

step :: PosToken -> ([Int] -> [PosToken]) -> ([Int] -> [PosToken])

-- start blocks must be indented
-- tokens before the current layout end the current layout
step t next (col:cols)

  | usesLayout t && posColumn t > col = t : next (posColumn t:col:cols)

  | usesLayout t && posColumn t == col = t{posToken=LayoutSep}
                                       : t : next (col:cols)

  | posColumn t <= col = t{posToken=LayoutEnd} : step t next cols

step t next cols = t : next cols


-- | Return True when a token starts a layout scope.
usesLayout :: PosToken -> Bool
usesLayout t
  | Section{} <- posToken t = True
  | Bullet    <- posToken t = True
  | otherwise               = False
