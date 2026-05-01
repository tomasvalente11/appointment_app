import PropTypes from 'prop-types'

export default function GuestInfo({ guestEmail, guestName }) {
  return (
    <div>
      <p className='font-medium text-gray-900 text-sm'>{guestName}</p>
      <p className='text-gray-500 text-xs'>{guestEmail}</p>
    </div>
  )
}

GuestInfo.propTypes = {
  guestEmail: PropTypes.string.isRequired,
  guestName: PropTypes.string.isRequired,
}
