<!DOCTYPE html>
<html>

<head>
    <title>IOSA Restaurant Menu</title>

    <meta name="viewport"
        content="width=device-width, initial-scale=1">

    <meta name="csrf-token"
        content="{{ csrf_token() }}">

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
        rel="stylesheet">

    <style>
        body {
            background: #f5f7fa;
            padding-bottom: 90px;
        }

        .product-card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, .08);
        }

        .price {
            color: #198754;
            font-weight: bold;
            font-size: 17px;
        }

        .cart-bar {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: white;
            box-shadow: 0 -2px 10px rgba(0, 0, 0, .10);
            padding: 12px;
            z-index: 999;
        }
    </style>
</head>

<body>

    <div class="container py-3">

        <div class="text-center mb-4">
            <h2>🍽 Table {{ $table->table_name }}</h2>
            <div class="text-muted">Scan • Order • Enjoy</div>
        </div>

        <div class="row">
            @foreach($products as $product)
            <div class="col-6 mb-3">
                <div class="card product-card h-100">
                    <div class="card-body d-flex flex-column">
                        <h6>{{ $product->name }}</h6>

                        <div class="price mt-auto">
                            Rs {{ number_format($product->selling_price, 2) }}
                        </div>

                        <button class="btn btn-success btn-sm mt-2 add-product"
                            data-id="{{ $product->id }}"
                            data-name="{{ $product->name }}"
                            data-price="{{ $product->selling_price }}">
                            + Add
                        </button>
                    </div>
                </div>
            </div>
            @endforeach
        </div>

    </div>

    <div class="cart-bar">
        <div class="d-flex justify-content-between align-items-center">
            <div>
                <strong id="cart-count">0</strong> Items |
                Rs <strong id="cart-total">0.00</strong>
            </div>

            <button class="btn btn-primary"
                data-bs-toggle="modal"
                data-bs-target="#cartModal">
                View Cart
            </button>
        </div>
    </div>

    <div class="modal fade"
        id="cartModal"
        tabindex="-1">

        <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable">
            <div class="modal-content">

                <div class="modal-header">
                    <h5 class="modal-title">Your Order</h5>
                    <button type="button"
                        class="btn-close"
                        data-bs-dismiss="modal"></button>
                </div>

                <div class="modal-body">
                    <div id="cart-items"></div>

                    <textarea id="order-notes"
                        class="form-control mt-3"
                        rows="2"
                        placeholder="Any special instruction?"></textarea>
                </div>

                <div class="modal-footer d-block">
                    <div class="d-flex justify-content-between mb-3">
                        <strong>Total</strong>
                        <strong>Rs <span id="modal-total">0.00</span></strong>
                    </div>

                    <button class="btn btn-success w-100"
                        id="submit-order">
                        Submit Order
                    </button>
                </div>

            </div>
        </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

    <script>
        let cart = {};

        function updateCartDisplay() {
            let count = 0;
            let total = 0;

            Object.values(cart).forEach(item => {
                count += item.quantity;
                total += item.quantity * item.price;
            });

            document.getElementById('cart-count').innerText = count;
            document.getElementById('cart-total').innerText = total.toFixed(2);
            document.getElementById('modal-total').innerText = total.toFixed(2);

            const cartItems = document.getElementById('cart-items');

            if (count === 0) {
                cartItems.innerHTML = '<div class="text-muted text-center">No items added</div>';
                return;
            }

            cartItems.innerHTML = '';

            Object.values(cart).forEach(item => {
                cartItems.innerHTML += `
                <div class="border rounded p-2 mb-2">
                    <div class="fw-bold">${item.name}</div>
                    <div class="text-success">Rs ${item.price.toFixed(2)}</div>

                    <div class="d-flex align-items-center mt-2">
                        <button class="btn btn-sm btn-outline-danger"
                                onclick="decreaseQty(${item.id})">-</button>

                        <span class="mx-3">${item.quantity}</span>

                        <button class="btn btn-sm btn-outline-success"
                                onclick="increaseQty(${item.id})">+</button>
                    </div>
                </div>
            `;
            });
        }

        document.querySelectorAll('.add-product').forEach(button => {
            button.addEventListener('click', function() {
                const id = parseInt(this.dataset.id);
                const name = this.dataset.name;
                const price = parseFloat(this.dataset.price);

                if (!cart[id]) {
                    cart[id] = {
                        id: id,
                        name: name,
                        price: price,
                        quantity: 1
                    };
                } else {
                    cart[id].quantity++;
                }

                updateCartDisplay();
            });
        });

        function increaseQty(id) {
            cart[id].quantity++;
            updateCartDisplay();
        }

        function decreaseQty(id) {
            cart[id].quantity--;

            if (cart[id].quantity <= 0) {
                delete cart[id];
            }

            updateCartDisplay();
        }

        document.getElementById('submit-order').addEventListener('click', async function() {
            const items = Object.values(cart);

            if (items.length === 0) {
                alert('Please add at least one item.');
                return;
            }

            this.disabled = true;
            this.innerText = 'Submitting...';

            const response = await fetch("{{ url('/customer-menu/table/' . $table->id . '/order') }}", {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content,
                    'Accept': 'application/json'
                },
                body: JSON.stringify({
                    items: items,
                    notes: document.getElementById('order-notes').value
                })
            });

            const data = await response.json();

            if (data.success) {
                cart = {};
                updateCartDisplay();

                alert(data.message);

                location.reload();
            } else {
                alert('Failed to submit order.');
            }

            this.disabled = false;
            this.innerText = 'Submit Order';
        });

        updateCartDisplay();
    </script>

</body>

</html>