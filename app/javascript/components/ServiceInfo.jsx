import PropTypes from 'prop-types'

export default function ServiceInfo({ service }) {
  if (!service) {
    return <p className='text-gray-400 text-xs'>{window.I18n?.requests?.no_service ?? 'No service specified'}</p>
  }

  return (
    <div>
      <p className='font-medium text-gray-800 text-sm'>{service.name}</p>
      <p className='text-gray-500 text-xs'>{service.location}</p>
    </div>
  )
}

ServiceInfo.propTypes = {
  service: PropTypes.shape({
    location: PropTypes.string.isRequired,
    name: PropTypes.string.isRequired,
  }),
}
