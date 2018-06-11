{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

-- | Utility and base types and functions for the Discord Rest API
module Network.Discord.Rest.Prelude where

import Data.Monoid ((<>))
import Network.HTTP.Req ((=:))
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Network.HTTP.Req as R

import Network.Discord.Types


authHeader :: DiscordAuth -> R.Option 'R.Https
authHeader (DiscordAuth auth version) =
          R.header "Authorization" (formatAuth auth)
       <> R.header "User-Agent" agent
  where
  srcUrl  = "https://github.com/aquarial/Discord.hs"
  forkUrl = "https://github.com/jano017/Discord.hs"
  agent = "DiscordBot (" <> srcUrl <> ", " <> TE.encodeUtf8 version <> ") "
                         <> " currently forking and rewriting " <> forkUrl

-- Append to an URL
infixl 5 //
(//) :: Show a => R.Url scheme -> a -> R.Url scheme
url // part = url R./: T.pack (show part)


type Option = R.Option 'R.Https

-- | Represtents a HTTP request made to an API that supplies a Json response
data JsonRequest where
  Delete ::                 R.Url 'R.Https         -> Option -> JsonRequest
  Get    ::                 R.Url 'R.Https         -> Option -> JsonRequest
  Patch  :: R.HttpBody a => R.Url 'R.Https ->    a -> Option -> JsonRequest
  Put    :: R.HttpBody a => R.Url 'R.Https ->    a -> Option -> JsonRequest
  Post   :: R.HttpBody a => R.Url 'R.Https -> IO a -> Option -> JsonRequest

-- | Represents a range of 'Snowflake's
data Range = Range { after :: Snowflake, before :: Snowflake, limit :: Int}

maxRange :: Range
maxRange = Range 0 18446744073709551615 100
--                       2^64 - 1

-- | Convert a Range to a query string
rangeToOption :: Range -> Option
rangeToOption (Range a b l)
  =  "after"  =: show a
  <> "before" =: show b
  <> "limit"  =: show l


