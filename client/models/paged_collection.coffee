exports.PagedCollection = class PagedCollection extends Backbone.Collection
  nextCheck: /<([^>]*)>; rel="next"/
  prevCheck: /<([^>]*)>; rel="prev"/
  
  # Idea to do URL overriding stolen from https://gist.github.com/838460
  # but parsing the next/prev from the HTTP Response headers, which are raw
  # links, instead of page indexes
  parse: (response, xhr) =>
    links = xhr.getResponseHeader('Link')
    
    this.parseLinks(links)
    
    return response
  
  fillData: (links, data) =>
    this.parseLinks(links)
    this.reset(data, parse: true)
  
  parseLinks: (links) =>
    nextMatch = this.nextCheck.exec(links)
    if nextMatch?
      this.next = nextMatch[1]
    else
      this.next = null
      
    prevMatch = this.prevCheck.exec(links)
    if prevMatch?
      this.prev = prevMatch[1]
    else
      this.prev = null
  
  setQueryString: (queryString) =>
    if queryString?
      this.url = this.baseUrl + '?' + queryString
    else
      this.url = this.baseUrl
