import PropTypes from 'prop-types'
import { useEffect } from 'react'

const COLORS = {
  accepted: 'bg-green-600',
  rejected: 'bg-gray-700',
}

export default function Toast({ message, onDismiss, status }) {
  useEffect(() => {
    const timer = setTimeout(onDismiss, 3500)
    return () => clearTimeout(timer)
  }, [onDismiss])

  return (
    <div className={`${COLORS[status] || 'bg-gray-700'} bottom-6 fixed flex gap-3 items-center left-1/2 px-5 py-3 rounded-xl shadow-lg text-sm text-white -translate-x-1/2`}>
      <span>{message}</span>
      <button className='opacity-70 hover:opacity-100' onClick={onDismiss}>&times;</button>
    </div>
  )
}

Toast.propTypes = {
  message: PropTypes.string.isRequired,
  onDismiss: PropTypes.func.isRequired,
  status: PropTypes.string.isRequired,
}
