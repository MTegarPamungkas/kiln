# notify-user

Appwrite Function (Node 22) that sends a push notification to a single user
through Appwrite Messaging. Deployed on the reference self-hosted server and
invoked by the `appwrite_demo` example through the `CloudFunctions` contract
(`functions.createExecutions`).

## Request

```json
{ "toUser": "<user id>", "title": "Kiln", "body": "Hello!" }
```

`title` and `body` are optional (`New message` / empty). Responds
`{ ok: true, toUser, title, body }` or `{ ok: false, error, code, type }`.

## Deployment lessons (self-hosted 2.7.2)

These cost real debugging time — do not rediscover them:

1. **The function has no API key by default.** Appwrite 2.x does not inject
   `APPWRITE_API_KEY` into function runtimes. Create a function variable
   (`POST /functions/{id}/variables`, `variableId` + `key` + `value`) holding
   a scoped API key (`messages.write`) and read it in the handler.
2. **Use the public endpoint.** The runtime's `APPWRITE_FUNCTION_API_ENDPOINT`
   is the internal `http://appwrite/v1`, which redirects to the public HTTPS
   origin — a redirect `node-appwrite` does not follow. Set a
   `PUBLIC_ENDPOINT` variable and prefer it over the env endpoint.
3. **Ship `node-appwrite` yourself.** The runtime image does not preinstall
   it; add it to `package.json` dependencies and keep
   `commands: "npm install"` on the function.
4. **`scopes` matters.** The function's API key needs `messages.write` for
   `messaging.createPush` (`messaging.write` is rejected as an unknown scope).
5. **Push create route** is `POST /messaging/messages/push` (with
   `users` / `topics` / `targets` for fan-out). The generic
   `POST /messaging/messages` is not registered on 2.7.2.

## Deploy

```bash
tar -czf deploy.tar.gz src package.json
curl -X POST "https://<host>/v1/functions/notify-user/deployments" \
  -H "X-Appwrite-Project: <project>" -H "X-Appwrite-Key: <api key>" \
  -F "code=@deploy.tar.gz" -F "activate=true"
```

Wait for the deployment status to become `ready` (npm install runs during the
build), then execute with the desired body.
