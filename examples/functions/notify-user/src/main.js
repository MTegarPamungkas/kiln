module.exports = async function (context) {
  const sdk = require('node-appwrite');
  // The internal endpoint (http://appwrite/v1) triggers an https redirect the
  // SDK does not follow; talk to the public endpoint directly.
  const endpoint = process.env.PUBLIC_ENDPOINT || process.env.APPWRITE_FUNCTION_API_ENDPOINT;
  const client = new sdk.Client()
    .setEndpoint(endpoint)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);
  const messaging = new sdk.Messaging(client);

  const payload = context.req.bodyJson || {};
  const toUser = typeof payload.toUser === 'string' ? payload.toUser.trim() : '';
  const title = typeof payload.title === 'string' && payload.title.trim()
    ? payload.title.trim().slice(0, 90)
    : 'New message';
  const body = typeof payload.body === 'string' ? payload.body.slice(0, 280) : '';

  if (!toUser) {
    return context.res.json(
      { ok: false, error: 'toUser (user id) is required' },
      400,
    );
  }

  try {
    await messaging.createPush({
      messageId: sdk.ID.unique(),
      title,
      body,
      users: [toUser],
      draft: false,
    });
    context.log('push sent to ' + toUser);
    return context.res.json({ ok: true, toUser, title, body });
  } catch (error) {
    context.error(String(error));
    return context.res.json(
      {
        ok: false,
        error: String(error),
        code: error.code,
        type: error.type,
      },
      502,
    );
  }
};
