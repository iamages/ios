# ios
iOS (& Mac Catalyst) client for Iamages.

## URL scheme
`iamages://` scheme
- `feed`, `search`, `upload`, `you` to open the corresponding app views. 
    - Example: `iamages://feed` to open the Feed view.
- `view` to open a viewer.
    - `?type=file` or `collection`: specifies what resource does `id` refer to.
    - `&id=`: ID of the resource.
    - Example: `iamages://view?type=file&id=f5Xk3JVeuJkLKqpQqwBEbu` to open a sheet viewer for the file with ID `f5Xk3JVeuJkLKqpQqwBEbu`.
