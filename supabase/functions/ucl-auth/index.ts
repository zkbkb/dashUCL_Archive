import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

// Get UCL API credentials from environment variables
const clientId = Deno.env.get('UCL_CLIENT_ID')
const clientSecret = Deno.env.get('UCL_CLIENT_SECRET')

// Helper function to create redirect response
function createRedirectResponse(url: string) {
  return new Response(null, {
    status: 302,
    headers: {
      'Location': url,
      'Cache-Control': 'no-store',
    },
  })
}

serve(async (req) => {
  // Handle direct callback from UCL API
  if (req.method === 'GET') {
    const url = new URL(req.url)
    console.log('Received callback URL:', url.toString())
    console.log('Search params:', Object.fromEntries(url.searchParams))
    
    const code = url.searchParams.get('code')
    const state = url.searchParams.get('state')
    const error = url.searchParams.get('error')
    const result = url.searchParams.get('result')

    // Check environment variables
    if (!clientId || !clientSecret) {
      console.error('Missing environment variables:', { clientId: !!clientId, clientSecret: !!clientSecret })
      return createRedirectResponse(`dashucl://callback?error=server_configuration_error`)
    }

    if (error) {
      console.error('Received error from UCL:', error)
      return createRedirectResponse(`dashucl://callback?error=${error}`)
    }

    if (!code) {
      console.error('No code received in callback')
      return createRedirectResponse(`dashucl://callback?error=no_code`)
    }

    if (result !== 'allowed') {
      console.error('Authorization not allowed:', result)
      return createRedirectResponse(`dashucl://callback?error=not_allowed`)
    }

    try {
      console.log('Starting token exchange with code:', code)
      // 1. Exchange code for UCL token
      const tokenUrl = new URL('https://uclapi.com/oauth/token')
      tokenUrl.searchParams.append('client_id', clientId)
      tokenUrl.searchParams.append('client_secret', clientSecret)
      tokenUrl.searchParams.append('code', code)
      
      const tokenResponse = await fetch(tokenUrl.toString())
      const tokenData = await tokenResponse.json()
      console.log('Token response:', { ok: tokenData.ok, error: tokenData.error })
      
      if (!tokenData.ok) {
        console.error('Token exchange failed:', tokenData)
        return createRedirectResponse(`dashucl://callback?error=token_exchange_failed&details=${encodeURIComponent(JSON.stringify(tokenData))}`)
      }

      console.log('Getting user data with token:', tokenData.token)
      // 2. Get user information
      const userUrl = new URL('https://uclapi.com/oauth/user/data')
      userUrl.searchParams.append('token', tokenData.token)
      userUrl.searchParams.append('client_secret', clientSecret)
      
      const userResponse = await fetch(userUrl.toString())
      const userData = await userResponse.json()
      console.log('User data response:', { ok: userData.ok, error: userData.error })

      if (!userData.ok) {
        console.error('User data fetch failed:', userData)
        return createRedirectResponse(`dashucl://callback?error=user_data_failed&details=${encodeURIComponent(JSON.stringify(userData))}`)
      }

      // 3. Redirect to iOS app with necessary data
      const redirectData = {
        ok: true,
        token: tokenData.token,
        state: state,
        user: userData
      }
      
      const encodedData = encodeURIComponent(JSON.stringify(redirectData))
      console.log('Redirecting back to app with success')
      return createRedirectResponse(`dashucl://callback?data=${encodedData}`)

    } catch (error) {
      console.error('Error in auth flow:', error)
      return createRedirectResponse(`dashucl://callback?error=server_error&details=${encodeURIComponent(error.message)}`)
    }
  }

  // Return 405 Method Not Allowed for other HTTP methods
  console.log('Received non-GET request:', req.method)
  return new Response('Method Not Allowed', { status: 405 })
}) 