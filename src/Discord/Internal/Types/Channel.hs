{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

-- | Data structures pertaining to Discord Channels
module Discord.Internal.Types.Channel where

import Control.Applicative (empty)
import Data.Aeson
import Data.Aeson.Types (Parser)
import Data.Monoid ((<>))
import Data.Text (Text)
import Data.Time.Clock
import qualified Data.Text as T

import Discord.Internal.Types.Prelude
import Discord.Internal.Types.User (User(..))
import Discord.Internal.Types.Embed

-- | Guild channels represent an isolated set of users and messages in a Guild (Server)
data Channel
  -- | A text channel in a guild.
  = ChannelText
      { channelId          :: ChannelId   -- ^ The id of the channel (Will be equal to
                                          --   the guild if it's the "general" channel).
      , channelGuild       :: GuildId     -- ^ The id of the guild.
      , channelName        :: T.Text      -- ^ The name of the guild (2 - 1000 characters).
      , channelPosition    :: Maybe Integer     -- ^ The storing position of the channel.
      , channelPermissions :: [Overwrite] -- ^ An array of permission 'Overwrite's
      , channelUserRateLimit :: Integer   -- ^ Seconds before a user can speak again
      , channelNSFW        :: Bool        -- ^ Is not-safe-for-work
      , channelTopic       :: T.Text      -- ^ The topic of the channel. (0 - 1024 chars).
      , channelParentId    :: Maybe ChannelId
      , channelLastMessage :: Maybe MessageId   -- ^ The id of the last message sent in the
                                                --   channel
      }
  | ChannelNews
      { channelId          :: ChannelId
      , channelGuild       :: GuildId
      , channelName        :: T.Text
      , channelPosition    :: Maybe Integer
      , channelPermissions :: [Overwrite]
      , channelNSFW        :: Bool
      , channelTopic       :: T.Text
      , channelParentId    :: Maybe ChannelId
      , channelLastMessage :: Maybe MessageId
      }
  | ChannelStorePage
      { channelId          :: ChannelId
      , channelGuild       :: GuildId
      , channelName        :: T.Text
      , channelPosition    :: Maybe Integer
      , channelNSFW        :: Bool
      , channelParentId    :: Maybe ChannelId
      , channelPermissions :: [Overwrite]
      }
  -- | A voice channel in a guild.
  | ChannelVoice
      { channelId          :: ChannelId
      , channelGuild       :: GuildId
      , channelName        :: T.Text
      , channelPosition    :: Maybe Integer
      , channelPermissions :: [Overwrite]
      , channelNSFW        :: Bool
      , channelBitRate     :: Integer     -- ^ The bitrate (in bits) of the channel.
      , channelParentId    :: Maybe ChannelId
      , channelUserLimit   :: Integer     -- ^ The user limit of the voice channel.
      }
  -- | DM Channels represent a one-to-one conversation between two users, outside the scope
  --   of guilds
  | ChannelDirectMessage
      { channelId          :: ChannelId
      , channelRecipients  :: [User]      -- ^ The 'User' object(s) of the DM recipient(s).
      , channelParentId    :: Maybe ChannelId
      , channelLastMessage :: Maybe MessageId
      }
  | ChannelGroupDM
      { channelId          :: ChannelId
      , channelRecipients  :: [User]
      , channelParentId    :: Maybe ChannelId
      , channelLastMessage :: Maybe MessageId
      }
  | ChannelGuildCategory
      { channelId          :: ChannelId
      , channelPosition    :: Maybe Integer
      , channelName        :: T.Text
      , channelParentId    :: Maybe ChannelId
      , channelGuild       :: GuildId
      } deriving (Show, Eq, Ord)

instance FromJSON Channel where
  parseJSON = withObject "Channel" $ \o -> do
    type' <- (o .: "type") :: Parser Int
    case type' of
      0 ->
        ChannelText  <$> o .:  "id"
                     <*> o .:? "guild_id" .!= 0
                     <*> o .:  "name"
                     <*> o .:? "position"
                     <*> o .:  "permission_overwrites"
                     <*> o .:  "rate_limit_per_user"
                     <*> o .:? "nsfw" .!= False
                     <*> o .:? "topic" .!= ""
                     <*> o .:? "parent_id"
                     <*> o .:? "last_message_id"
      1 ->
        ChannelDirectMessage <$> o .:  "id"
                             <*> o .:  "recipients"
                             <*> o .:? "parent_id"
                             <*> o .:? "last_message_id"
      2 ->
        ChannelVoice <$> o .:  "id"
                     <*> o .:? "guild_id" .!= 0
                     <*> o .:  "name"
                     <*> o .:? "position"
                     <*> o .:  "permission_overwrites"
                     <*> o .:? "nsfw" .!= False
                     <*> o .:  "bitrate"
                     <*> o .:? "parent_id"
                     <*> o .:  "user_limit"
      3 ->
        ChannelGroupDM <$> o .:  "id"
                       <*> o .:  "recipients"
                       <*> o .:? "parent_id"
                       <*> o .:? "last_message_id"
      4 ->
        ChannelGuildCategory <$> o .: "id"
                             <*> o .:? "position"
                             <*> o .: "name"
                             <*> o .:? "parent_id"
                             <*> o .:? "guild_id" .!= 0
      5 ->
        ChannelNews <$> o .:  "id"
                    <*> o .:? "guild_id" .!= 0
                    <*> o .:  "name"
                    <*> o .:? "position"
                    <*> o .:  "permission_overwrites"
                    <*> o .:? "nsfw" .!= False
                    <*> o .:? "topic" .!= ""
                    <*> o .:? "parent_id"
                    <*> o .:? "last_message_id"
      6 ->
        ChannelStorePage <$> o .:  "id"
                         <*> o .:? "guild_id" .!= 0
                         <*> o .:  "name"
                         <*> o .:? "position"
                         <*> o .:? "nsfw" .!= False
                         <*> o .:? "parent_id"
                         <*> o .:  "permission_overwrites"
      _ -> fail ("Unknown channel type:" <> show type')

instance ToJSON Channel where
  toJSON ChannelText{..} = object [(name,value) | (name, Just value) <-
              [ ("id",     toJSON <$> pure channelId)
              , ("guild_id", toJSON <$> pure channelGuild)
              , ("name",  toJSON <$> pure channelName)
              , ("position",   toJSON <$> channelPosition)
              , ("rate_limit_per_user", toJSON <$> pure channelUserRateLimit)
              , ("nsfw", toJSON <$> pure channelNSFW)
              , ("permission_overwrites",   toJSON <$> pure channelPermissions)
              , ("topic",   toJSON <$> pure channelTopic)
              , ("parent_id", toJSON <$> channelParentId)
              , ("last_message_id",  toJSON <$> channelLastMessage)
              ] ]
  toJSON ChannelNews{..} = object [(name,value) | (name, Just value) <-
              [ ("id",     toJSON <$> pure channelId)
              , ("guild_id", toJSON <$> pure channelGuild)
              , ("name",  toJSON <$> pure channelName)
              , ("position",   toJSON <$> channelPosition)
              , ("permission_overwrites",   toJSON <$> pure channelPermissions)
              , ("nsfw", toJSON <$> pure channelNSFW)
              , ("topic",   toJSON <$> pure channelTopic)
              , ("parent_id", toJSON <$> channelParentId)
              , ("last_message_id",  toJSON <$> channelLastMessage)
              ] ]
  toJSON ChannelStorePage{..} = object [(name,value) | (name, Just value) <-
              [ ("id",     toJSON <$> pure channelId)
              , ("guild_id", toJSON <$> pure channelGuild)
              , ("name",  toJSON <$> pure channelName)
              , ("nsfw", toJSON <$> pure channelNSFW)
              , ("position",   toJSON <$> channelPosition)
              , ("parent_id", toJSON <$> channelParentId)
              , ("permission_overwrites",   toJSON <$> pure channelPermissions)
              ] ]
  toJSON ChannelDirectMessage{..} = object [(name,value) | (name, Just value) <-
              [ ("id",     toJSON <$> pure channelId)
              , ("recipients",   toJSON <$> pure channelRecipients)
              , ("parent_id", toJSON <$> channelParentId)
              , ("last_message_id",  toJSON <$> channelLastMessage)
              ] ]
  toJSON ChannelVoice{..} = object [(name,value) | (name, Just value) <-
              [ ("id",     toJSON <$> pure channelId)
              , ("guild_id", toJSON <$> pure channelGuild)
              , ("name",  toJSON <$> pure channelName)
              , ("position",   toJSON <$> channelPosition)
              , ("nsfw", toJSON <$> pure channelNSFW)
              , ("permission_overwrites",   toJSON <$> pure channelPermissions)
              , ("bitrate",   toJSON <$> pure channelBitRate)
              , ("parent_id", toJSON <$> channelParentId)
              , ("user_limit",  toJSON <$> pure channelUserLimit)
              ] ]
  toJSON ChannelGroupDM{..} = object [(name,value) | (name, Just value) <-
              [ ("id",     toJSON <$> pure channelId)
              , ("recipients",   toJSON <$> pure channelRecipients)
              , ("parent_id", toJSON <$> channelParentId)
              , ("last_message_id",  toJSON <$> channelLastMessage)
              ] ]
  toJSON ChannelGuildCategory{..} = object [(name,value) | (name, Just value) <-
              [ ("id",     toJSON <$> pure channelId)
              , ("guild_id", toJSON <$> pure channelGuild)
              , ("name", toJSON <$> pure channelName)
              , ("parent_id", toJSON <$> channelParentId)
              , ("position", toJSON <$> channelPosition)
              ] ]

-- | If the channel is part of a guild (has a guild id field)
channelIsInGuild :: Channel -> Bool
channelIsInGuild c = case c of
        ChannelGuildCategory{..} -> True
        ChannelText{..} -> True
        ChannelVoice{..}  -> True
        ChannelNews{..}  -> True
        ChannelStorePage{..}  -> True
        _ -> False

-- | Permission overwrites for a channel.
data Overwrite = Overwrite
  { overwriteId    :: OverwriteId -- ^ 'Role' or 'User' id
  , overwriteType  :: T.Text    -- ^ Either "role" or "member
  , overwriteAllow :: Integer   -- ^ Allowed permission bit set
  , overwriteDeny  :: Integer   -- ^ Denied permission bit set
  } deriving (Show, Eq, Ord)

instance FromJSON Overwrite where
  parseJSON = withObject "Overwrite" $ \o ->
    Overwrite <$> o .: "id"
              <*> o .: "type"
              <*> o .: "allow"
              <*> o .: "deny"

instance ToJSON Overwrite where
  toJSON Overwrite{..} = object
              [ ("id",     toJSON overwriteId)
              , ("type",   toJSON overwriteType)
              , ("allow",  toJSON overwriteAllow)
              , ("deny",   toJSON overwriteDeny)
              ]

-- | Represents information about a message in a Discord channel.
data Message = Message
  { messageId           :: MessageId       -- ^ The id of the message
  , messageChannel      :: ChannelId       -- ^ Id of the channel the message
                                           --   was sent in
  , messageAuthor       :: User            -- ^ The 'User' the message was sent
                                           --   by
  , messageText         :: Text            -- ^ Contents of the message
  , messageTimestamp    :: UTCTime         -- ^ When the message was sent
  , messageEdited       :: Maybe UTCTime   -- ^ When/if the message was edited
  , messageTts          :: Bool            -- ^ Whether this message was a TTS
                                           --   message
  , messageEveryone     :: Bool            -- ^ Whether this message mentions
                                           --   everyone
  , messageMentions     :: [User]          -- ^ 'User's specifically mentioned in
                                           --   the message
  , messageMentionRoles :: [RoleId]        -- ^ 'Role's specifically mentioned in
                                           --   the message
  , messageAttachments  :: [Attachment]    -- ^ Any attached files
  , messageEmbeds       :: [Embed]         -- ^ Any embedded content
  , messageNonce        :: Maybe Nonce     -- ^ Used for validating if a message
                                           --   was sent
  , messagePinned       :: Bool            -- ^ Whether this message is pinned
  , messageGuild        :: Maybe GuildId   -- ^ The guild the message went to
  } deriving (Show, Eq, Ord)

instance FromJSON Message where
  parseJSON = withObject "Message" $ \o ->
    Message <$> o .:  "id"
            <*> o .:  "channel_id"
            <*> (do isW <- o .:? "webhook_id"
                    a <- o .: "author"
                    case isW :: Maybe WebhookId of
                      Nothing -> pure a
                      Just _ -> pure $ a { userIsWebhook = True })
            <*> o .:? "content" .!= ""
            <*> o .:? "timestamp" .!= epochTime
            <*> o .:? "edited_timestamp"
            <*> o .:? "tts" .!= False
            <*> o .:? "mention_everyone" .!= False
            <*> o .:? "mentions" .!= []
            <*> o .:? "mention_roles" .!= []
            <*> o .:? "attachments" .!= []
            <*> o .:  "embeds"
            <*> o .:? "nonce"
            <*> o .:? "pinned" .!= False
            <*> o .:? "guild_id" .!= Nothing

-- | Represents an attached to a message file.
data Attachment = Attachment
  { attachmentId       :: Snowflake     -- ^ Attachment id
  , attachmentFilename :: T.Text        -- ^ Name of attached file
  , attachmentSize     :: Integer       -- ^ Size of file (in bytes)
  , attachmentUrl      :: T.Text        -- ^ Source of file
  , attachmentProxy    :: T.Text        -- ^ Proxied url of file
  , attachmentHeight   :: Maybe Integer -- ^ Height of file (if image)
  , attachmentWidth    :: Maybe Integer -- ^ Width of file (if image)
  } deriving (Show, Eq, Ord)

instance FromJSON Attachment where
  parseJSON = withObject "Attachment" $ \o ->
    Attachment <$> o .:  "id"
               <*> o .:  "filename"
               <*> o .:  "size"
               <*> o .:  "url"
               <*> o .:  "proxy_url"
               <*> o .:? "height"
               <*> o .:? "width"



newtype Nonce = Nonce T.Text
  deriving (Show, Eq, Ord)

instance FromJSON Nonce where
  parseJSON (String nonce) = pure $ Nonce nonce
  parseJSON (Number nonce) = pure . Nonce . T.pack . show $ nonce
  parseJSON _ = empty
