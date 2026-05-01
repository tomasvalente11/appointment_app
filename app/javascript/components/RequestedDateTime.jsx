import PropTypes from 'prop-types'

export default function RequestedDateTime({ requestedAt }) {
  const locale = window.I18n?.locale === 'pt' ? 'pt-PT' : 'en-GB'
  const date = new Date(requestedAt)
  const dateStr = date.toLocaleDateString(locale, { day: '2-digit', month: 'short', year: 'numeric' })
  const timeStr = date.toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })

  return (
    <div>
      <p className='font-medium text-gray-800 text-sm'>{dateStr}</p>
      <p className='text-gray-500 text-xs'>{timeStr}</p>
    </div>
  )
}

RequestedDateTime.propTypes = {
  requestedAt: PropTypes.string.isRequired,
}
