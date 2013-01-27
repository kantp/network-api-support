{-# LANGUAGE OverloadedStrings, CPP #-}
module Network.Api.Support.Request (
  RequestTransformer
, setApiKey
, setParams
, setHeaders
, setMethod
, setBody
, setBodyLazy
, setJson
, (<>)
) where

import Control.Monad.Trans.Resource

import qualified Data.ByteString as B
import qualified Data.ByteString.Lazy as BL
import Data.Aeson
import Data.CaseInsensitive
import Data.Monoid

import Network.HTTP.Conduit

-- * Request transformers

-- | A RequestTransformer allows you to build up attributes on the request.
-- | RequestTransformer is simply an Endo, and therefore has a Monoid, so
-- | can be combined with `<>`.
type RequestTransformer m = Endo (Request (ResourceT m))

-- | Set an api key for use with basic auth.
setApiKey :: B.ByteString -> RequestTransformer m
setApiKey key = Endo $ applyBasicAuth key ""

-- | Set request query parameters.
setParams :: Monad m => [(B.ByteString, B.ByteString)] -> RequestTransformer m
setParams params = Endo $ urlEncodedBody params

-- | Set request headers.
setHeaders :: [(CI B.ByteString, B.ByteString)] -> RequestTransformer m
setHeaders m = Endo $ \r -> r { requestHeaders = m }

-- | Set the request method to be the specified name.
setMethod :: B.ByteString -> RequestTransformer m
setMethod m = Endo $ \r -> r { method = m }

-- | Set the request body from the specified byte string.
setBody :: B.ByteString -> RequestTransformer m
setBody b = Endo $ \r -> r { requestBody = RequestBodyBS b }

-- | Set the request body from the specified lazy byte string.
setBodyLazy :: BL.ByteString -> RequestTransformer m
setBodyLazy b = Endo $ \r -> r { requestBody = RequestBodyLBS b }

-- | Set the request body from the value which can be converted to JSON.
setJson :: ToJSON a => a -> RequestTransformer m
setJson = setBodyLazy . encode . toJSON

-- * Compatability

#if __GLASGOW_HASKELL__ < 704
infixr 5 <>
(<>) :: Monoid m => m -> m -> m
(<>) = mappend
#endif
