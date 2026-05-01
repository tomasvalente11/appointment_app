import PropTypes from 'prop-types'

export default function EmptyState({ filter }) {
  const e = window.I18n?.requests?.empty ?? {}
  const message = e[filter] ?? (filter === 'pending'
    ? 'No pending requests.'
    : filter === 'answered'
      ? 'No answered requests yet.'
      : 'No appointment requests yet.')

  return (
    <div className='py-20 text-center text-gray-400'>
      <p className='font-medium text-lg'>{message}</p>
      <p className='mt-1 text-sm'>{e.hint ?? 'Requests from guests will appear here.'}</p>
    </div>
  )
}

EmptyState.propTypes = {
  filter: PropTypes.string.isRequired,
}
