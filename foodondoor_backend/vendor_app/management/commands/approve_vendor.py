from django.core.management.base import BaseCommand, CommandError
from vendor_app.models import VendorProfile

class Command(BaseCommand):
    help = 'Approve a vendor by phone number or id (UUID)'

    def add_arguments(self, parser):
        parser.add_argument('--phone', type=str, help='Phone number of the vendor to approve')
        parser.add_argument('--id', type=str, help='UUID of the vendor to approve')

    def handle(self, *args, **options):
        phone = options['phone']
        vendor_id = options['id']
        try:
            if phone:
                vendor = VendorProfile.objects.get(phone_number=phone)
            elif vendor_id:
                vendor = VendorProfile.objects.get(id=vendor_id)
            else:
                raise CommandError('Please provide either --phone or --id to approve a vendor.')
            vendor.is_approved = True
            vendor.save()
            self.stdout.write(self.style.SUCCESS(f'Vendor {vendor} approved successfully.'))
        except VendorProfile.DoesNotExist:
            raise CommandError('Vendor not found with the provided identifier.')
