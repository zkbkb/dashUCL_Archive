import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"

// Get UCL API credentials from environment variables
const clientSecret = Deno.env.get('UCL_CLIENT_SECRET')

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request URL
    const url = new URL(req.url)
    const endpoint = url.pathname.replace('/ucl-proxy', '')  // Remove prefix
    const token = url.searchParams.get('token')
    
    console.log('Request details:', {
      originalUrl: url.toString(),
      endpoint,
      token: token ? token.substring(0, 10) + '...' : null,
      clientSecret: clientSecret ? '✓' : '✗'
    })
    
    // Validate required parameters
    if (!token) {
      return new Response(
        JSON.stringify({ ok: false, error: 'Missing token parameter' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (!clientSecret) {
      console.error('Missing UCL_CLIENT_SECRET environment variable')
      return new Response(
        JSON.stringify({ ok: false, error: 'Server configuration error' }),
        { 
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Build UCL API request
    const uclApiUrl = new URL(`https://uclapi.com${endpoint}`)
    
    // Add all query parameters
    url.searchParams.forEach((value, key) => {
      if (key !== 'token') {  // Skip original token parameter
        uclApiUrl.searchParams.append(key, value)
      }
    })
    
    // Add necessary authentication parameters
    uclApiUrl.searchParams.append('token', token)
    uclApiUrl.searchParams.append('client_secret', clientSecret)

    console.log(`Making request to UCL API: ${uclApiUrl.toString().replace(clientSecret, '[SECRET]')}`)

    // Send request to UCL API
    const response = await fetch(uclApiUrl.toString(), {
      method: req.method,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    })

    // Get response content type
    const contentType = response.headers.get('content-type')
    
    // Record response basic information
    console.log(`UCL API response status:`, {
      status: response.status,
      contentType: contentType,
      headers: Object.fromEntries(response.headers.entries())
    })

    // Clone response so we can read content multiple times
    const responseClone = response.clone()
    
    // Process response based on content type and status code
    let data
    let responseText = ''
    
    // First try reading response text for logging
    try {
      responseText = await responseClone.text()
      // Limit log length to first 300 characters
      console.log(`Response preview: ${responseText.substring(0, 300)}${responseText.length > 300 ? '...' : ''}`)
    } catch (error) {
      console.error('Failed to read response text:', error)
      responseText = 'Failed to read response text'
    }
    
    // Check if response is JSON
    const isJsonResponse = contentType && contentType.includes('application/json')
    
    if (isJsonResponse) {
      try {
        // If content type is JSON, try parsing JSON
        data = JSON.parse(responseText)
      } catch (error) {
        console.error('Failed to parse JSON response:', error)
        
        // Return parsing error
        return new Response(
          JSON.stringify({ 
            ok: false, 
            error: 'Invalid JSON from UCL API',
            details: error.message,
            endpoint: endpoint,
            status: response.status
          }),
          { 
            status: 502, // Bad Gateway
            headers: { ...corsHeaders, 'Content-Type': 'application/json' }
          }
        )
      }
    } else {
      // Non-JSON response, return formatted error information
      console.error(`UCL API returned non-JSON response: ${contentType || 'unknown content type'}`)
      
      return new Response(
        JSON.stringify({ 
          ok: false, 
          error: 'UCL API returned non-JSON response',
          details: `Content-Type: ${contentType || 'unknown'}`,
          previewContent: responseText.substring(0, 200),
          endpoint: endpoint,
          status: response.status
        }),
        { 
          status: 502, // Bad Gateway
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }
    
    // Record response status
    console.log(`Parsed UCL API response:`, {
      status: response.status,
      ok: data.ok !== undefined ? data.ok : 'undefined',
      error: data.error,
    })

    // Return response
    return new Response(
      JSON.stringify(data),
      { 
        status: response.status,
        headers: { 
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )

  } catch (error) {
    console.error('Proxy error:', error.stack || error)
    return new Response(
      JSON.stringify({ 
        ok: false, 
        error: 'Internal server error in UCL API proxy',
        details: error.message,
        stack: Deno.env.get('ENVIRONMENT') === 'development' ? error.stack : undefined
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}) 